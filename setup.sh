#!/bin/bash
# setup.sh: Robust system & profile bootstrapper.
# Usage: sudo ./setup.sh [dev|rev|pwn]

set -euo pipefail

# --- Configuration ---
REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
REAL_USER="${SUDO_USER:-$(whoami)}"
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

# --- Logging ---
log() { echo -e "\033[0;32m[INFO]\033[0m $1"; }
warn() { echo -e "\033[0;33m[WARN]\033[0m $1"; }
error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; exit 1; }

# --- Root Guard ---
if [ "$EUID" -ne 0 ]; then
    error "Please run as root: sudo $0"
fi

# ==========================================
# PHASE 1: SYSTEM CONFIGURATION (ROOT)
# ==========================================

install_base_deps() {
    log "Installing base dependencies..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -q
    apt-get install -y -q ca-certificates curl gnupg unzip git build-essential stow wget openssh-server fuse pipx
}

install_docker_official() {
    if command -v docker &>/dev/null; then 
        log "Docker is already installed."
        return 0
    fi
    log "Installing Docker (Official Repo)..."

    # Determine the correct upstream ID and codename for Docker's repositories
    . /etc/os-release
    local DOCKER_OS_ID="$ID"
    local DOCKER_CODENAME="$VERSION_CODENAME"

    # For distros like Kali or Parrot that are Debian-based but don't have their own Docker repo.
    if [[ "${PRETTY_NAME}" == *"Parrot"* || "$ID" == "parrot" || "$ID" == "kali" ]]; then
        warn "Docker does not provide a repo for '${PRETTY_NAME}'. Using the upstream Debian 'bookworm' repo instead."
        DOCKER_OS_ID="debian"
        DOCKER_CODENAME="bookworm"
    fi

    # 1. Setup Keyrings using the correct OS ID
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL "https://download.docker.com/linux/${DOCKER_OS_ID}/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # 2. Add Repo using the correct OS ID and Codename
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DOCKER_OS_ID $DOCKER_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # 3. Install
    apt-get update -q
    apt-get install -y -q docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # 4. Permissions
    usermod -aG docker "$REAL_USER"
}

harden_ssh() {
    log "Hardening SSH..."
    local CONFIG_CONTENT="PubkeyAuthentication yes
PasswordAuthentication no
PermitRootLogin no
ChallengeResponseAuthentication no"

    if [ -d "/etc/ssh/sshd_config.d" ] && grep -q "^Include /etc/ssh/sshd_config.d" /etc/ssh/sshd_config; then
        echo "$CONFIG_CONTENT" > /etc/ssh/sshd_config.d/99-hardening.conf
    else
        warn "sshd_config.d not supported or included. Appending to main config."
        cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
        echo "$CONFIG_CONTENT" >> /etc/ssh/sshd_config
    fi
    
    # Ensure the privilege separation directory exists for sshd -t check
    mkdir -p /run/sshd
    if sshd -t; then
        log "SSH configuration validated."
    else
        error "SSH Config syntax check failed. Reverting changes..."
        rm -f /etc/ssh/sshd_config.d/99-hardening.conf 2>/dev/null || mv /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
        exit 1
    fi
}

install_mise_system_binary() {
    if command -v mise &>/dev/null; then 
        log "mise is already installed."
        return 0
    fi
    log "Installing Mise binary..."
    
    install -m 0755 -d /etc/apt/keyrings
    wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | tee /etc/apt/keyrings/mise-archive-keyring.gpg > /dev/null
    echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=amd64] https://mise.jdx.dev/deb stable main" | tee /etc/apt/sources.list.d/mise.list > /dev/null
    
    apt-get update -q
    apt-get install -y -q mise
}

# ==========================================
# PHASE 2: USER CONFIGURATION (DE-ELEVATED)
# ==========================================

configure_user_environment() {
    local REPO_DIR="$1"
    shift
    local PROFILES=($@)
    local CONFIG_FILE="$HOME/.config/mise/config.toml"

    log "Configuring Mise profiles for user $(whoami)..."

    mkdir -p "$(dirname "$CONFIG_FILE")"
    
    # Start with the base.toml content, which includes headers and base tools.
    cp "$REPO_DIR/mise/base.toml" "$CONFIG_FILE"

    for p in "${PROFILES[@]}"; do
        if [ -f "$REPO_DIR/mise/$p.profile" ]; then
            log "Adding tools from profile: $p"
            echo "" >> "$CONFIG_FILE" # Add a newline for readability
            cat "$REPO_DIR/mise/$p.profile" >> "$CONFIG_FILE"
        fi
    done

    log "Installing tools with mise..."
    mise trust --yes
    mise install -y

    stow_dotfiles "$REPO_DIR"

}

stow_dotfiles() {
    local REPO_DIR="$1"
    log "Stowing dotfiles..."
    
    if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
        warn "Backing up existing .zshrc to .zshrc.bak..."
        mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
    fi

    # Core dotfiles that should always be stowed
    local CORE_PACKAGES=(zsh tmux eza git vivid nvim alacritty hypr kanshi waybar)

    for pkg in "${CORE_PACKAGES[@]}"; do
        if [ -d "${REPO_DIR}/${pkg}" ]; then
            log "Stowing '${pkg}'..."
            stow --dir="$REPO_DIR" --target="$HOME" --restow "$pkg" 2>/dev/null || warn "Stow found conflicts for '${pkg}'. It might be partially stowed."
        fi
    done
}

# --- Main Execution ---
main() {
    local PROFILES=()
    # --- Argument Parser ---
    while [[ $# -gt 0 ]]; do
        case $1 in
            all)
                PROFILES+=("dev" "rev" "pwn")
                shift
                ;; 
            *)
                PROFILES+=("$1")
                shift
                ;; 
        esac
    done

    # Add 'base' profile and remove duplicates.
    PROFILES+=("base")
    PROFILES=($(echo "${PROFILES[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

    # --- Phase 1: Root operations ---
    install_base_deps
    install_docker_official
    harden_ssh
    install_mise_system_binary

    # --- Phase 2: User operations ---
    log "Changing ownership of user's .local directory..."
    mkdir -p "$USER_HOME/.local"
    chown -R "$REAL_USER":"$REAL_USER" "$USER_HOME/.local" || warn "Could not chown .local, mise may fail."
    
    log "Switching to user '$REAL_USER' to configure user environment..."

    # Serialize the required functions to pass them to the user's shell, since 'su -' creates a clean environment.
    local func_defs
    # Important: List all functions that are needed by configure_user_environment and its children.
    func_defs=$(declare -f log warn error stow_dotfiles configure_user_environment)
    
    local profiles_str="${PROFILES[*]}"

    # Build the command to be executed by the user's shell.
    # This approach is more robust for passing context (functions, vars) into the new shell.
    local user_command="
        ${func_defs} # This contains only function definitions.
        export -f log warn error stow_dotfiles configure_user_environment # Explicitly export them now.
        configure_user_environment '${REPO_DIR}' ${profiles_str}
    "
    
    # Execute the command string as the target user.
    su - "$REAL_USER" -c "${user_command}"
}

main "$@"
