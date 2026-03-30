#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

sync_nvim() {
    # Ensure mise is active if present so we can find nvim
    if command -v mise &>/dev/null; then
        eval "$(mise activate bash)"
    elif [ -f /usr/bin/mise ]; then
        eval "$(/usr/bin/mise activate bash)"
    fi

    if ! command_exists nvim; then
        warn "nvim command not found, skipping plugin sync."
        return 0
    fi

    log "Synchronizing Neovim Lazy plugins..."
    nvim --headless "+Lazy! sync" +qa
    log "Neovim sync complete."
}

sync_nvim
