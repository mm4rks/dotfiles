#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

configure_mise() {
    local PROFILES=("$@")
    # REPO_DIR should be set by the calling script, but we provide a default.
    local REPO_DIR=${REPO_DIR:-"$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"/.. &>/dev/null && pwd)"}
    local CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/mise/config.toml"

    # Ensure ~/.local/bin is in PATH for local installations
    export PATH="${HOME}/.local/bin:${PATH}"

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

    # Create Pure prompt symlinks for the mise-installed version
    local PURE_DIR
    PURE_DIR=$(mise where npm:pure-prompt 2>/dev/null || true)
    if [ -n "$PURE_DIR" ]; then
        # mise where returns the root of the npm package installation
        # For npm packages, the actual files are often in lib/node_modules/pure-prompt
        # but mise-npm might symlink them differently. Let's find the files.
        local TARGET_DIR
        if [ -f "$PURE_DIR/pure.zsh" ]; then
            TARGET_DIR="$PURE_DIR"
        elif [ -f "$PURE_DIR/lib/node_modules/pure-prompt/pure.zsh" ]; then
            TARGET_DIR="$PURE_DIR/lib/node_modules/pure-prompt"
        fi

        if [ -n "${TARGET_DIR:-}" ]; then
            log "Creating symlinks for Pure prompt in $TARGET_DIR..."
            [ ! -f "$TARGET_DIR/prompt_pure_setup" ] && ln -sf "pure.zsh" "$TARGET_DIR/prompt_pure_setup"
            [ ! -f "$TARGET_DIR/async" ] && ln -sf "async.zsh" "$TARGET_DIR/async"
        fi
    fi
}

# The main user_setup.sh script should pass its arguments to this script.
configure_mise "$@"
