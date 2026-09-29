#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

stow_dotfiles() {
    # REPO_DIR should be set by the calling script, but we provide a default.
    local REPO_DIR=${REPO_DIR:-"$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"/.. &>/dev/null && pwd)"}
    
    log "Stowing dotfiles..."
    
    local rc
    for rc in .zshrc .zshenv; do
        if [ -f "$HOME/$rc" ] && [ ! -L "$HOME/$rc" ]; then
            warn "Backing up existing $rc to $rc.bak..."
            mv "$HOME/$rc" "$HOME/$rc.bak"
        fi
    done

    local CORE_PACKAGES=(zsh tmux eza git vivid nvim voxtype starship)
    for pkg in "${CORE_PACKAGES[@]}"; do
        if [ -d "${REPO_DIR}/${pkg}" ]; then
            log "Stowing '${pkg}'..."
            stow --dir="$REPO_DIR" --target="$HOME" --restow "$pkg" 2>/dev/null || warn "Stow found conflicts for '${pkg}'. It might be partially stowed."
        fi
    done


}

stow_dotfiles
