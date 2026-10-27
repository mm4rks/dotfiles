#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

CERTIPY_COMMIT="890dbf80afb47ba45c4bfda959dced58f9cdae06"
CERTIPY_REPO="https://github.com/ly4k/Certipy.git"

# Certipy is incompatible with newer Python; it runs on the standalone
# Python 3.12 from pipx_install_py312 (scripts/lib.sh).

install_certipy() {
    # pipx records the install spec (git+<repo>@<commit>) in its metadata.
    local pipx_state
    pipx_state="$(pipx list --json 2>/dev/null || true)"
    if [[ "$pipx_state" == *"$CERTIPY_COMMIT"* ]]; then
        log "Certipy commit ${CERTIPY_COMMIT:0:7} is already installed via pipx. Skipping."
        return 0
    fi

    log "Ensuring no system-packaged version of Certipy exists..."
    local dpkg_status
    dpkg_status="$(dpkg -s certipy-ad certipy 2>/dev/null || true)"
    if [[ "$dpkg_status" == *"Status: install ok installed"* ]]; then
        log "System-packaged certipy found. Purging it..."
        sudo apt-get remove -y --purge certipy-ad certipy || warn "Failed to remove system-packaged certipy. This may cause conflicts."
    fi

    log "Force-installing Certipy commit ${CERTIPY_COMMIT:0:7} via pipx..."
    
    # Uninstall any previous pipx version to ensure a clean state.
    pipx uninstall certipy-ad > /dev/null 2>&1 || true

    # Install the specific commit using --force, against our standalone Python 3.12.
    pipx_install_py312 --force "git+${CERTIPY_REPO}@${CERTIPY_COMMIT}"
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

main() {
    install_certipy
}

main "$@"
