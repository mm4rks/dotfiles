#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)
CORE_PACKAGES=(zsh tmux eza git vivid nvim)

stow_dotfiles() {
    log "Stowing dotfiles..."

    local rc
    for rc in .zshrc .zshenv; do
        if [ -f "$HOME/$rc" ] && [ ! -L "$HOME/$rc" ]; then
            local backup
            backup="$HOME/$rc.bak.$(date +%Y%m%d%H%M%S)"
            warn "Backing up existing $rc to ${backup}..."
            mv "$HOME/$rc" "$backup"
        fi
    done

    local pkg
    for pkg in "${CORE_PACKAGES[@]}"; do
        if [ -d "${REPO_DIR}/${pkg}" ]; then
            log "Stowing '${pkg}'..."
            stow --dir="$REPO_DIR" --target="$HOME" --restow "$pkg" || warn "Stow found conflicts for '${pkg}' (see above). It might be partially stowed."
        fi
    done
}

main() {
    stow_dotfiles
}

main "$@"
