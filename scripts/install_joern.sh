#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

JOERN_VERSION="v4.0.510"
JOERN_URL="https://github.com/joernio/joern/releases/download/${JOERN_VERSION}/joern-install.sh"
JOERN_SHA256="790a4c7e0d99a71a101292189e6607c62b2e8aafd81f41df177ffc61dfde26cf"

install_joern() {
    if command_exists joern; then
        log "Joern is already installed. Skipping."
        return 0
    fi
    log "Installing Joern ${JOERN_VERSION}..."

    local TEMP_DIR
    TEMP_DIR="$(mktemp -d)"
    trap "rm -rf '$TEMP_DIR'" RETURN

    local installer_path="${TEMP_DIR}/joern-install.sh"
    download_and_verify "$JOERN_URL" "$installer_path" "$JOERN_SHA256"

    chmod +x "$installer_path"
    # Joern's script uses sudo internally if not run as root, so this is safe.
    "$installer_path" --non-interactive
    log "Joern installed successfully."
}

install_joern
