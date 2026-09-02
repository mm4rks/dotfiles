#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

# Installs the pipx/npm-based tools that used to come from mise/rev.profile.

SEMGREP_VERSION="1.76.0"
# 9.4.0 is the pinned floor for the "ghidra" extra (needs flare-capa's
# PyGhidra backend, added after 8.0.1 -- see mandiant/capa#2600).
FLARE_CAPA_VERSION="9.4.0"

install_pipx_tool() {
    local name="$1" spec="$2"
    if pipx list --short 2>/dev/null | grep -q "^${name} "; then
        log "${name} is already installed via pipx."
        return 0
    fi
    log "Installing ${spec} via pipx..."
    pipx install "$spec"
}

install_cdxgen() {
    if command_exists cdxgen; then
        log "cdxgen is already installed."
        return 0
    fi
    if ! command_exists npm; then
        warn "npm not found. Skipping cdxgen install."
        return 0
    fi
    log "Installing @cyclonedx/cdxgen via npm..."
    npm install -g @cyclonedx/cdxgen
}

install_rev_pipx_tools() {
    if ! command_exists pipx; then
        error "pipx not found. Ensure scripts/install_base_deps.sh ran first."
    fi

    install_pipx_tool "semgrep" "semgrep==${SEMGREP_VERSION}"
    # [ghidra] extra pulls in pyghidra, capa's Ghidra analysis backend;
    # GHIDRA_INSTALL_DIR is set up by install_ghidra.sh.
    install_pipx_tool "flare-capa" "flare-capa[ghidra]==${FLARE_CAPA_VERSION}"
    install_pipx_tool "apkleaks" "apkleaks"
    install_cdxgen
}

install_rev_pipx_tools
