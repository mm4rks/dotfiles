#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

GHIDRA_VERSION="12.1.2"
GHIDRA_BUILD="Ghidra_12.1.2_build"
GHIDRA_DATE="20260605"
GHIDRA_URL="https://github.com/NationalSecurityAgency/ghidra/releases/download/${GHIDRA_BUILD}/ghidra_${GHIDRA_VERSION}_PUBLIC_${GHIDRA_DATE}.zip"
GHIDRA_SHA256="b62e81a0390618466c019c60d8c2f796ced2509c4c1aea4a37644a77272cf99d"

FORCE=false

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
    ensure_dependencies

    if command_exists ghidra && [ "$FORCE" != true ]; then
        log "Ghidra is already installed. Skipping (use --force to reinstall/upgrade to ${GHIDRA_VERSION})."
        return 0
    fi

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

    rm -rf /opt/ghidra
    mv "$extracted_dir" /opt/ghidra
    ln -sf /opt/ghidra/ghidraRun /usr/local/bin/ghidra
    log "Ghidra installed successfully."
}

# Persists GHIDRA_INSTALL_DIR so capa's PyGhidra backend (flare-capa[ghidra])
# can find this install without the user having to set it up manually.
export_ghidra_home() {
    local ghidra_home="/opt/ghidra"

    local target_user="${SUDO_USER:-$(whoami)}"
    local target_home
    target_home="$(getent passwd "$target_user" | cut -d: -f6)"

    if [ -z "$target_home" ] || [ ! -d "$target_home" ]; then
        warn "Could not resolve home directory for ${target_user}. Skipping bashrc export."
        return 0
    fi

    local bashrc="${target_home}/.bashrc"
    local start_marker="# >>> dotfiles GHIDRA_INSTALL_DIR >>>"
    local end_marker="# <<< dotfiles GHIDRA_INSTALL_DIR <<<"

    touch "$bashrc"
    if grep -qF "$start_marker" "$bashrc"; then
        sed -i "/${start_marker}/,/${end_marker}/d" "$bashrc"
    fi

    {
        echo "$start_marker"
        echo "export GHIDRA_INSTALL_DIR=\"${ghidra_home}\""
        echo "$end_marker"
    } >> "$bashrc"
    chown "$target_user":"$target_user" "$bashrc"

    log "Exported GHIDRA_INSTALL_DIR=${ghidra_home} in ${bashrc}."
}

main() {
    if [[ $EUID -ne 0 ]]; then
       error "This script must be run as root (use sudo)."
    fi

    for arg in "$@"; do
        case "$arg" in
            --force) FORCE=true ;;
            *) error "Unknown argument: ${arg}" ;;
        esac
    done

    install_ghidra
    export_ghidra_home
}

main "$@"
