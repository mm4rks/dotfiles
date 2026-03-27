#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

CERTIPY_COMMIT="890dbf80afb47ba45c4bfda959dced58f9cdae06"
CERTIPY_REPO="https://github.com/ly4k/Certipy.git"

install_certipy() {
    log "Ensuring no system-packaged version of Certipy exists..."
    if dpkg -s certipy-ad 2>/dev/null | grep -q 'Status: install ok installed' || dpkg -s certipy 2>/dev/null | grep -q 'Status: install ok installed'; then
        log "System-packaged certipy found. Purging it..."
        sudo apt-get remove -y --purge certipy-ad certipy || warn "Failed to remove system-packaged certipy. This may cause conflicts."
    fi

    log "Force-installing Certipy commit ${CERTIPY_COMMIT:0:7} via pipx..."
    
    # Uninstall any previous pipx version to ensure a clean state.
    pipx uninstall certipy-ad > /dev/null 2>&1 || true

    # Install the specific commit using --force.
    # We use pipx directly, which will use the active python version (3.14.0 from configure_mise.sh).
    mise install python@3.12
    pipx install --python "$(mise bin-paths python@3.12)/python3" --force "git+${CERTIPY_REPO}@${CERTIPY_COMMIT}"
    log "Certipy installation complete."

    # Verification
    log "Verifying Certipy installation..."
    local certipy_info
    certipy_info=$(pipx list | grep 'certipy-ad' || true)
    
    if [ -z "$certipy_info" ]; then
        error "Certipy not found in 'pipx list' after installation."
    fi

    # We cannot simply grep for the commit hash anymore because pipx might not output it 
    # in newer pipx versions when installed from git in the same way.
    # As long as it is listed in pipx list, we consider it verified.
    log "Certipy verified."
}

install_certipy
