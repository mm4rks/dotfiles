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
    local installed_version
    installed_version="$(pipx list --short 2>/dev/null | awk -v n="$name" '$1 == n {print $2}')"

    if [ -n "$installed_version" ]; then
        # Pull the pinned version (if any) out of specs like
        # "flare-capa[ghidra]==9.4.0"; specs with no "==" (e.g. "apkleaks")
        # are left unpinned and any installed version is accepted.
        local desired_version="${spec##*==}"
        if [ "$desired_version" = "$spec" ] || [ "$installed_version" = "$desired_version" ]; then
            log "${name} is already installed via pipx (${installed_version})."
            return 0
        fi
        log "${name} ${installed_version} installed via pipx, but ${spec} is pinned. Reinstalling..."
        pipx install --force "$spec"
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
