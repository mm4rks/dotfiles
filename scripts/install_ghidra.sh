#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

GHIDRA_VERSION="12.0.4"
GHIDRA_BUILD="Ghidra_12.0.4_build"
GHIDRA_DATE="20260303"
GHIDRA_URL="https://github.com/NationalSecurityAgency/ghidra/releases/download/${GHIDRA_BUILD}/ghidra_${GHIDRA_VERSION}_PUBLIC_${GHIDRA_DATE}.zip"
GHIDRA_SHA256="c3b458661d69e26e203d739c0c82d143cc8a4a29d9e571f099c2cf4bda62a120"

ensure_dependencies() {
    log "Checking for Ghidra dependencies..."

    # Check for unzip
    if ! command_exists unzip; then
        log "Installing unzip..."
        apt-get update -qq && apt-get install -y -qq unzip
    fi

    # Ensure Java 21 is installed
    "$(dirname "$0")/install_java.sh"
}

install_ghidra() {
    if command_exists ghidra; then
        log "Ghidra is already installed. Skipping."
        return 0
    fi
    
    ensure_dependencies
    log "Installing Ghidra ${GHIDRA_VERSION}..."

    local TEMP_DIR
    TEMP_DIR="$(mktemp -d)"
    trap "rm -rf '$TEMP_DIR'" RETURN

    local archive_path="${TEMP_DIR}/ghidra.zip"
    download_and_verify "$GHIDRA_URL" "$archive_path" "$GHIDRA_SHA256"

    log "Extracting Ghidra..."
    unzip -q -o "$archive_path" -d "${TEMP_DIR}"

    # Find the name of the single directory created by the zip extraction.
    local extracted_dir
    extracted_dir=$(find "${TEMP_DIR}" -mindepth 1 -maxdepth 1 -type d)

    if [ -z "$extracted_dir" ] || [ ! -d "$extracted_dir" ]; then
        error "Could not find extracted Ghidra directory in ${TEMP_DIR}."
    fi
    
    mv "$extracted_dir" /opt/ghidra
    ln -sf /opt/ghidra/ghidraRun /usr/local/bin/ghidra
    log "Ghidra installed successfully."
}

main() {
    if [[ $EUID -ne 0 ]]; then
       error "This script must be run as root (use sudo)."
    fi
    install_ghidra
}

main "$@"
