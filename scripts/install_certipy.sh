#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

CERTIPY_COMMIT="890dbf80afb47ba45c4bfda959dced58f9cdae06"
CERTIPY_REPO="https://github.com/ly4k/Certipy.git"

install_certipy() {
    log "Ensuring no system-packaged version of Certipy exists..."
    if dpkg -s certipy-ad 2>/dev/null | grep -q 'Status: install ok installed' || dpkg -s certipy 2>/dev/null | grep -q 'Status: install ok installed'; then
        log "System-packaged certipy found. Purging it..."
        apt-get remove -y --purge certipy-ad certipy || warn "Failed to remove system-packaged certipy. This may cause conflicts."
    fi

    log "Force-installing Certipy commit ${CERTIPY_COMMIT:0:7} via pipx..."
    
    # Uninstall any previous pipx version to ensure a clean state.
    pipx uninstall certipy-ad > /dev/null 2>&1 || true

    # Install the specific commit using --force.
    # This relies on the correct python version being on the PATH,
    # which is handled by `configure_mise.sh` setting a global default.
    pipx install --force "git+${CERTIPY_REPO}@${CERTIPY_COMMIT}"
    log "Certipy installation complete."

    # Verification
    log "Verifying Certipy installation..."
    local certipy_info
    certipy_info=$(pipx list | grep 'certipy-ad' || true)
    
    if [ -z "$certipy_info" ]; then
        error "Certipy not found in 'pipx list' after installation."
    fi

    if ! echo "$certipy_info" | grep -q "$CERTIPY_COMMIT"; then
        error "Certipy commit hash mismatch. Expected ${CERTIPY_COMMIT:0:7}. Full info: $certipy_info"
    fi
    log "Certipy verified."
}

install_certipy
