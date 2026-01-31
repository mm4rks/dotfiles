#!/bin/bash
# user_setup.sh: User-level environment configuration.
# This script is intended to be run as a regular user, not as root.

set -euo pipefail

# --- Configuration ---
REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# --- Logging ---
log() { echo -e "\033[0;32m[INFO]\033[0m $1"; }
warn() { echo -e "\033[0;33m[WARN]\033[0m $1"; }
error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; exit 1; }

# --- User-level functions ---

stow_dotfiles() {
    local REPO_DIR="$1"
    log "Stowing dotfiles..."
    
    if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
        warn "Backing up existing .zshrc to .zshrc.bak..."
        mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
    fi

    local CORE_PACKAGES=(zsh tmux eza git vivid nvim alacritty hypr kanshi waybar)
    for pkg in "${CORE_PACKAGES[@]}"; do
        if [ -d "${REPO_DIR}/${pkg}" ]; then
            log "Stowing '${pkg}'..."
            stow --dir="$REPO_DIR" --target="$HOME" --restow "$pkg" 2>/dev/null || warn "Stow found conflicts for '${pkg}'. It might be partially stowed."
        fi
    done

    log "Synchronizing Neovim Lazy plugins..."
    nvim --headless "+Lazy! sync" +qa
}

configure_mise() {
    local PROFILES=($@)
    local CONFIG_FILE="$HOME/.config/mise/config.toml"

    log "Configuring Mise profiles for user $(whoami)..."
    mkdir -p "$(dirname "$CONFIG_FILE")"
    
    log "Adding mise plugins..."
    mise plugin add ghidra https://github.com/mise-plugins/mise-ghidra.git || true 
    
    log "Generating mise config..."
    cp "$REPO_DIR/mise/base.toml" "$CONFIG_FILE"
    for p in "${PROFILES[@]}"; do
        if [[ "$p" == "base" ]]; then continue; fi
        if [ -f "$REPO_DIR/mise/$p.profile" ]; then
            log "Adding tools from profile: $p"
            echo "" >> "$CONFIG_FILE"
            cat "$REPO_DIR/mise/$p.profile" >> "$CONFIG_FILE"
        fi
    done

    log "Installing tools with mise..."
    mise trust --yes
    mise install -y
}


# --- Main Execution ---
main() {
    eval "$(mise activate bash)"
    if [ "$EUID" -eq 0 ]; then
        error "This script should be run as a regular user, not as root."
    fi

    configure_mise "$@"
    stow_dotfiles "$REPO_DIR"

    log "User setup complete!"
}

main "$@"
