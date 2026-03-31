#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

install_mise_binary() {
    if command_exists mise; then
        log "mise is already installed."
        return 0
    fi
    
    if [ "$EUID" -eq 0 ]; then
        log "Installing Mise binary system-wide..."
        install -m 0755 -d /etc/apt/keyrings
        wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | tee /etc/apt/keyrings/mise-archive-keyring.gpg > /dev/null
        local MISE_ARCH
        MISE_ARCH="$(dpkg --print-architecture)"
        echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=${MISE_ARCH}] https://mise.jdx.dev/deb stable main" | tee /etc/apt/sources.list.d/mise.list > /dev/null

        apt-get update -q
        apt-get install -y -q mise
    else
        log "Installing Mise binary locally..."
        curl https://mise.jdx.dev/install.sh | sh
        # Ensure ~/.local/bin is in path for current session
        export PATH="$HOME/.local/bin:$PATH"
    fi
}

install_mise_binary
