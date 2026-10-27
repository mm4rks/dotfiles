#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

# 2026-10-14: first commit depending on certipy-nxc from PyPI. Older commits
# pull the unpinned Pennyw0rth/Certipy fork, whose package was renamed, and
# no longer install.
NETEXEC_COMMIT="6c312cd79165aebeeea28cd9eac39c6103890bb0"

install_netexec() {
    # pipx records the install spec (git+<repo>@<commit>) in its metadata.
    local pipx_state
    pipx_state="$(pipx list --json 2>/dev/null || true)"
    if [[ "$pipx_state" == *"${NETEXEC_COMMIT}"* ]]; then
        log "NetExec (nxc) commit ${NETEXEC_COMMIT:0:7} is already installed. Skipping."
        return 0
    fi

    log "Installing NetExec (commit: ${NETEXEC_COMMIT:0:7})..."
    # Needs Python >= 3.11; Ubuntu 22.04 ships 3.10.
    pipx_install_py312 --force "git+https://github.com/Pennyw0rth/NetExec@${NETEXEC_COMMIT}"
    log "NetExec installation complete."
}

main() {
    install_netexec
}

main "$@"
