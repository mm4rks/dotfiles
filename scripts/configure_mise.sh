#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

configure_mise() {
    local PROFILES=("$@")
    # REPO_DIR should be set by the calling script, but we provide a default.
    local REPO_DIR=${REPO_DIR:-"$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"/.. &>/dev/null && pwd)"}
    local CONFIG_FILE="$HOME/.config/mise/config.toml"

    log "Configuring Mise profiles for user $(whoami)..."
    mkdir -p "$(dirname "$CONFIG_FILE")"
    
    if [ ! -f "$REPO_DIR/mise/base.toml" ]; then
        error "Could not find mise/base.toml in repo. Aborting."
    fi

    log "Generating mise config..."
    cp "$REPO_DIR/mise/base.toml" "$CONFIG_FILE"
    for p in "${PROFILES[@]}"; do
        if [ -f "$REPO_DIR/mise/$p.profile" ]; then
            log "Adding tools from profile: $p"
            echo "" >> "$CONFIG_FILE"
            cat "$REPO_DIR/mise/$p.profile" >> "$CONFIG_FILE"
        fi
    done

    log "Installing tools with mise..."
    mise trust --yes
    mise install -y

    log "Setting python@3.14.0 as the global default..."
    mise use --global python@3.14.0
}

# The main user_setup.sh script should pass its arguments to this script.
configure_mise "$@"
