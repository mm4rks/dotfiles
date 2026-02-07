#!/bin/bash
# system_setup.sh: Root-level system bootstrapper.
# This script should be run as root.

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
# SYSTEM CONFIGURATION (ROOT)
# ==========================================

install_base_deps() {
    log "Installing base dependencies..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq ca-certificates curl gnupg unzip git build-essential stow wget libfuse2 pipx libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev zsh linux-headers-generic libkrb5-dev cmake zsh-autosuggestions zsh-syntax-highlighting wl-clipboard xclip python3-dev
}

install_docker_official() {
    if command -v docker &>/dev/null; then 
        log "Docker is already installed."
        return 0
    fi
    log "Installing Docker (Official Repo)..."

    . /etc/os-release
    local DOCKER_OS_ID="$ID"
    local DOCKER_CODENAME="$VERSION_CODENAME"

    if [[ "${PRETTY_NAME}" == *"Parrot"* || "$ID" == "parrot" || "$ID" == "kali" ]]; then
        warn "Docker does not provide a repo for '${PRETTY_NAME}'. Using the upstream Debian 'bookworm' repo instead."
        DOCKER_OS_ID="debian"
        DOCKER_CODENAME="bookworm"
    fi

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL "https://download.docker.com/linux/${DOCKER_OS_ID}/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DOCKER_OS_ID $DOCKER_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    usermod -aG docker "$REAL_USER"
}

harden_ssh() {
    log "Hardening SSH..."
    local CONFIG_CONTENT="PubkeyAuthentication yes\nPasswordAuthentication no\nPermitRootLogin no\nChallengeResponseAuthentication no"
    if [ -d "/etc/ssh/sshd_config.d" ] && grep -q "^Include /etc/ssh/sshd_config.d" /etc/ssh/sshd_config; then
        echo -e "$CONFIG_CONTENT" > /etc/ssh/sshd_config.d/99-hardening.conf
    else
        warn "sshd_config.d not supported or included. Appending to main config."
        cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
        echo -e "$CONFIG_CONTENT" >> /etc/ssh/sshd_config
    fi
    
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

install_jetbrains_mono_nerd_font() {
    log "Installing JetBrainsMono Nerd Font..."

    if ! command -v fc-cache &> /dev/null; then
        warn "fc-cache not found. Skipping JetBrainsMono Nerd Font installation."
        return 0
    fi

    # Check if the font is already installed
    if fc-list | grep -qi "JetBrainsMono" && fc-list | grep -qi "Nerd Font"; then
        log "JetBrainsMono Nerd Font already appears to be installed (detected by fc-list). Skipping download and installation."
        return 0
    elif find "$FONT_DIR" -maxdepth 1 -iname "JetBrainsMono*.ttf" -print -quit | grep -q .; then
        log "JetBrainsMono font files already exist in $FONT_DIR. Assuming already installed, skipping download and installation."
        return 0
    fi

    local TEMP_DIR=""
    TEMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TEMP_DIR"' RETURN

    local FONT_DIR="/usr/local/share/fonts/NerdFonts"
    local FONT_ZIP="JetBrainsMono.zip"
    local FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/$FONT_ZIP"

    mkdir -p "$FONT_DIR"

    log "Downloading JetBrainsMono Nerd Font from ${FONT_URL}..."
    if ! wget -qO "${TEMP_DIR}/$FONT_ZIP" "$FONT_URL"; then
        warn "Failed to download JetBrainsMono Nerd Font. Skipping installation."
        return 1
    fi

    log "Unzipping font to $FONT_DIR..."
    if ! unzip -q -o "${TEMP_DIR}/$FONT_ZIP" -d "$FONT_DIR"; then
        warn "Failed to unzip JetBrainsMono Nerd Font. Skipping installation."
        return 1
    fi
    
    fc-cache -fv > /dev/null
    log "JetBrainsMono Nerd Font installed and cache refreshed."
}

install_bloodhound() {
    if command -v bloodhound-cli &>/dev/null; then
        log "bloodhound-cli is already installed. Skipping."
        return 0
    fi
    
    log "Installing BloodHound..."
    
    if command -v docker &>/dev/null; then
        warn "bloodhound-cli requires docker. abort"
        return 0
    fi

    local TEMP_DIR=""
    TEMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TEMP_DIR"' RETURN

    local BLOODHOUND_CLI_URL="https://github.com/SpecterOps/bloodhound-cli/releases/latest/download/bloodhound-cli-linux-amd64.tar.gz"
    
    log "Downloading bloodhound-cli from ${BLOODHOUND_CLI_URL}..."
    if ! curl --fail --location -o "${TEMP_DIR}/bloodhound-cli.tar.gz" "$BLOODHOUND_CLI_URL"; then
        error "Failed to download bloodhound-cli."
    fi
    
    tar -xzf "${TEMP_DIR}/bloodhound-cli.tar.gz" -C "${TEMP_DIR}"
    mv "${TEMP_DIR}/bloodhound-cli" /usr/local/bin/
}

install_joern() {
    if command -v joern &>/dev/null; then
        log "Joern is already installed. Skipping."
        return 0
    fi
    log "Installing Joern..."
    local TEMP_DIR=""
    TEMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TEMP_DIR"' RETURN
    curl -L "https://github.com/joernio/joern/releases/latest/download/joern-install.sh" -o "${TEMP_DIR}/joern-install.sh"
    chmod +x "${TEMP_DIR}/joern-install.sh"
    sudo "${TEMP_DIR}/joern-install.sh" --non-interactive
    log "Joern installed successfully."
}

install_ghidra() {
    if command -v ghidra &>/dev/null; then
        log "Ghidra is already installed. Skipping."
        return 0
    fi
    log "Installing Ghidra..."
    local TEMP_DIR=""
    TEMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TEMP_DIR"' RETURN

    local GHIDRA_URL
    GHIDRA_URL=$(curl -s https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/latest | jq -r '.assets[] | select(.name | endswith(".zip")) | .browser_download_url')
    if [ -z "$GHIDRA_URL" ]; then
        warn "Could not find Ghidra release URL. Skipping."
        return 1
    fi

    curl --fail --location -o "${TEMP_DIR}/ghidra.zip" "$GHIDRA_URL"
    local GHIDRA_DIR_NAME
    GHIDRA_DIR_NAME=$(unzip -Z -1 "${TEMP_DIR}/ghidra.zip" | head -1 | sed 's/\\\///')
    unzip -q -o "${TEMP_DIR}/ghidra.zip" -d "${TEMP_DIR}"
    
    mv "${TEMP_DIR}/${GHIDRA_DIR_NAME}" /opt/ghidra
    ln -sf /opt/ghidra/ghidraRun /usr/local/bin/ghidra
    log "Ghidra installed successfully."
}

main() {
    local PROFILES=("$@")

    install_base_deps
    install_docker_official
    install_mise_system_binary
    install_jetbrains_mono_nerd_font

    # 2. Loop directly over the provided args
    for profile in "${PROFILES[@]}"; do
        case "$profile" in
            ssh)
                log "Installing openssh-server..."
                apt-get install -y -qq openssh-server
                harden_ssh
                ;;
            pwn)
                install_bloodhound
                ;;
            rev)
                install_joern
                install_ghidra
                ;;
        esac
    done

    log "Changing ownership of user's .local directory..."
    mkdir -p "$USER_HOME/.local"
    chown -R "$REAL_USER":"$REAL_USER" "$USER_HOME/.local" || warn "Could not chown .local, mise may fail."
    chsh -s "$(which zsh)" "$REAL_USER"
    
    
    log "Switching to user '$REAL_USER' to run user setup..."
    su - "$REAL_USER" -c "bash ${REPO_DIR}/user_setup.sh ${PROFILES[*]}"
}

main "$@"
