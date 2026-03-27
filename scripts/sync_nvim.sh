#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

sync_nvim() {
    if ! command_exists nvim; then
        warn "nvim command not found, skipping plugin sync."
        return 0
    fi

    log "Synchronizing Neovim Lazy plugins..."
    nvim --headless "+Lazy! sync" +qa
    log "Neovim sync complete."
}

sync_nvim
