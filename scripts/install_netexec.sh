#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

NETEXEC_COMMIT="43027f47a2cdb388c3d7085d7fc9b5585a9845ed"

install_netexec() {
    if command_exists nxc; then
        log "NetExec (nxc) is already installed. Skipping."
        return 0
    fi

    log "Installing NetExec (commit: ${NETEXEC_COMMIT:0:7})..."
    pipx install --force "git+https://github.com/Pennyw0rth/NetExec@${NETEXEC_COMMIT}"
    log "NetExec installation complete."
}

install_netexec
