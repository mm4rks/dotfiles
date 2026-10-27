#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

POWERVIEW_COMMIT="5d7d57d80b5388360613e6441bdaebcde7be03da"

install_powerview() {
    # pipx records the install spec (git+<repo>@<commit>) in its metadata.
    local pipx_state
    pipx_state="$(pipx list --json 2>/dev/null || true)"
    if [[ "$pipx_state" == *"${POWERVIEW_COMMIT}"* ]]; then
        log "powerview.py commit ${POWERVIEW_COMMIT:0:7} is already installed. Skipping."
        return 0
    fi

    log "Installing powerview.py (commit: ${POWERVIEW_COMMIT:0:7})..."
    pipx install --force "git+https://github.com/aniqfakhrul/powerview.py@${POWERVIEW_COMMIT}"
    log "powerview.py installation complete."
}

main() {
    install_powerview
}

main "$@"
