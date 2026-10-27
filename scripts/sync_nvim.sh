#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

sync_nvim() {
    # Ensure local bins are in PATH for discovery
    export PATH="${LOCAL_PREFIX}/bin:${PATH}"

    if ! command_exists nvim; then
        warn "nvim command not found, skipping plugin sync."
        return 0
    fi

    log "Synchronizing Neovim Lazy plugins..."
    # restore, not sync: install exactly the commits in lazy-lock.json
    nvim --headless "+Lazy! restore" +qa
    log "Neovim sync complete."
}

main() {
    sync_nvim
}

main "$@"
