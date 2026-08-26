#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

# Installs the pipx/npm-based tools that used to come from mise/rev.profile.

SEMGREP_VERSION="1.76.0"
FLARE_CAPA_VERSION="8.0.1"

install_pipx_tool() {
    local name="$1" version="$2"
    if pipx list --short 2>/dev/null | grep -q "^${name} "; then
        log "${name} is already installed via pipx."
        return 0
    fi
    log "Installing ${name}==${version} via pipx..."
    if [ -n "$version" ]; then
        pipx install "${name}==${version}"
    else
        pipx install "$name"
    fi
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

    install_pipx_tool "semgrep" "$SEMGREP_VERSION"
    install_pipx_tool "flare-capa" "$FLARE_CAPA_VERSION"
    install_pipx_tool "apkleaks" ""
    install_cdxgen
}

install_rev_pipx_tools
