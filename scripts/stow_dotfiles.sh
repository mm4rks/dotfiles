#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

stow_dotfiles() {
    # REPO_DIR should be set by the calling script, but we provide a default.
    local REPO_DIR=${REPO_DIR:-"$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"/.. &>/dev/null && pwd)"}
    
    log "Stowing dotfiles..."
    
    if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
        warn "Backing up existing .zshrc to .zshrc.bak..."
        mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
    fi

    local CORE_PACKAGES=(zsh tmux eza git vivid nvim opencode starship)
    if is_omarchy; then
        CORE_PACKAGES+=(hypr)
    fi

    for pkg in "${CORE_PACKAGES[@]}"; do
        if [ -d "${REPO_DIR}/${pkg}" ]; then
            log "Stowing '${pkg}'..."
            stow --dir="$REPO_DIR" --target="$HOME" --restow "$pkg" 2>/dev/null || warn "Stow found conflicts for '${pkg}'. It might be partially stowed."
        fi
    done

    if is_omarchy && [ -d "${REPO_DIR}/applications" ]; then
        mkdir -p "$HOME/.local/share/applications"
        log "Stowing 'applications'..."
        stow --dir="$REPO_DIR" --target="$HOME/.local/share/applications" --restow applications 2>/dev/null || warn "Stow found conflicts for 'applications'. It might be partially stowed."
    fi
}

main() {
    stow_dotfiles "$@"
}
main "$@"
