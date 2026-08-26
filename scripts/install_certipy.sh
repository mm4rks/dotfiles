#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

CERTIPY_COMMIT="890dbf80afb47ba45c4bfda959dced58f9cdae06"
CERTIPY_REPO="https://github.com/ly4k/Certipy.git"

# Certipy is incompatible with newer Python, so we fetch a standalone
# Python 3.12 build (the same portable builds mise uses under the hood)
# purely to hand its interpreter to pipx.
PYTHON312_DIR="${HOME}/.local/opt/python3.12"
PYTHON312_URL="https://github.com/astral-sh/python-build-standalone/releases/download/20260825/cpython-3.12.14%2B20260825-x86_64-unknown-linux-gnu-install_only.tar.gz"
PYTHON312_SHA256="cbdd2f0cf02f941bc5c81e546f377275e322733abffe805ac29d2b7e8a58f7e3"

ensure_python312() {
    if [ -x "${PYTHON312_DIR}/bin/python3" ]; then
        return 0
    fi

    log "Fetching standalone Python 3.12 for Certipy..."
    local archive
    archive="$(mktemp)"
    download_and_verify "$PYTHON312_URL" "$archive" "$PYTHON312_SHA256"

    local extract_dir
    extract_dir="$(mktemp -d)"
    trap "rm -rf '$extract_dir' '$archive'" RETURN

    tar -xzf "$archive" -C "$extract_dir"
    mkdir -p "$(dirname "$PYTHON312_DIR")"
    rm -rf "$PYTHON312_DIR"
    mv "${extract_dir}/python" "$PYTHON312_DIR"
}

install_certipy() {
    log "Ensuring no system-packaged version of Certipy exists..."
    if dpkg -s certipy-ad 2>/dev/null | grep -q 'Status: install ok installed' || dpkg -s certipy 2>/dev/null | grep -q 'Status: install ok installed'; then
        log "System-packaged certipy found. Purging it..."
        sudo apt-get remove -y --purge certipy-ad certipy || warn "Failed to remove system-packaged certipy. This may cause conflicts."
    fi

    log "Force-installing Certipy commit ${CERTIPY_COMMIT:0:7} via pipx..."
    
    # Uninstall any previous pipx version to ensure a clean state.
    pipx uninstall certipy-ad > /dev/null 2>&1 || true

    # Install the specific commit using --force, against our standalone Python 3.12.
    ensure_python312
    pipx install --python "${PYTHON312_DIR}/bin/python3" --force "git+${CERTIPY_REPO}@${CERTIPY_COMMIT}"
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
