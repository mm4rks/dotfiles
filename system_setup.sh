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
    apt-get update -q
    apt-get install -y -q ca-certificates curl gnupg unzip git build-essential stow wget openssh-server fuse pipx libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev zsh
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

    apt-get update -q
    apt-get install -y -q docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
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

# --- Main Execution ---
main() {
    local PROFILES=()
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

    PROFILES+=("base")
    PROFILES=($(echo "${PROFILES[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

    install_base_deps
    install_docker_official
    harden_ssh
    install_mise_system_binary

    log "Changing ownership of user's .local directory..."
    mkdir -p "$USER_HOME/.local"
    chown -R "$REAL_USER":"$REAL_USER" "$USER_HOME/.local" || warn "Could not chown .local, mise may fail."
    
    log "Switching to user '$REAL_USER' to run user setup..."
    su - "$REAL_USER" -c "bash ${REPO_DIR}/user_setup.sh ${PROFILES[*]}"
}

main "$@"
