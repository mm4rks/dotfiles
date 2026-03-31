#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

BLOODHOUND_VERSION="0.2.0"
BLOODHOUND_URL="https://github.com/SpecterOps/bloodhound-cli/releases/download/v${BLOODHOUND_VERSION}/bloodhound-cli-linux-amd64.tar.gz"
BLOODHOUND_SHA256="072bd49bd2181681db460ab891a50ad4fe4cfddb7f7a35d8333c9248bf21eb8e"

install_bloodhound() {
    # Idempotency check
    if command_exists bloodhound-cli; then
        log "BloodHound CLI is already installed. Skipping."
        return 0
    fi

    log "Installing BloodHound CLI v${BLOODHOUND_VERSION}..."
    local TEMP_DIR
    TEMP_DIR="$(mktemp -d)"
    trap "rm -rf '$TEMP_DIR'" RETURN

        local archive_path="${TEMP_DIR}/bloodhound-cli.tar.gz"
        download_and_verify "$BLOODHOUND_URL" "$archive_path" "$BLOODHOUND_SHA256"
    
        tar -xzf "$archive_path" -C "${TEMP_DIR}"
        mv "${TEMP_DIR}/bloodhound-cli" /usr/local/bin/
        chmod +x /usr/local/bin/bloodhound-cli

    # Verification check
    log "Verifying BloodHound CLI by running the help command..."
    if ! bloodhound-cli help > /dev/null 2>&1; then
        error "Failed to execute 'bloodhound-cli help'. The binary may be corrupted or have unmet dependencies."
    fi
    log "BloodHound CLI verified."
}

install_bloodhound