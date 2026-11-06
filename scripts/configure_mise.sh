#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

# Maps a mise tool name to its system binary name.
tool_binary_name() {
    case "$1" in
        neovim) echo "nvim" ;;
        ripgrep) echo "rg" ;;
        *) echo "$1" ;;
    esac
}

# Filters a TOML file so tools already present in /usr/bin or /bin are not shadowed by mise,
# except for explicitly pinned runtimes (python, node, neovim) on Ubuntu/Kali.
filter_toml_avoid_system_shadow() {
    local src_file="$1"
    local dst_file="$2"
    local line tool bin_name

    while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" =~ ^([a-zA-Z0-9_-]+)[[:space:]]*= ]]; then
            tool="${BASH_REMATCH[1]}"
            bin_name="$(tool_binary_name "$tool")"
            if [[ "$tool" != "python" && "$tool" != "node" && "$tool" != "neovim" ]] && \
               { [ -x "/usr/bin/$bin_name" ] || [ -x "/bin/$bin_name" ]; }; then
                log "System binary '/usr/bin/$bin_name' already exists; skipping mise tool '$tool' to prevent shadowing."
                continue
            fi
        fi
        echo "$line" >> "$dst_file"
    done < "$src_file"
}

configure_mise() {
    if is_omarchy; then
        log "Omarchy detected. Skipping Mise configuration to avoid conflicting with Omarchy's Mise and system packages."
        return 0
    fi

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
    : > "$CONFIG_FILE"
    filter_toml_avoid_system_shadow "$REPO_DIR/mise/base.toml" "$CONFIG_FILE"
    for p in "${PROFILES[@]}"; do
        if [ -f "$REPO_DIR/mise/$p.profile" ]; then
            log "Adding tools from profile: $p"
            echo "" >> "$CONFIG_FILE"
            filter_toml_avoid_system_shadow "$REPO_DIR/mise/$p.profile" "$CONFIG_FILE"
        fi
    done

    log "Installing tools with mise..."
    mise trust --yes
    mise install -y
    mise reshim # Ensure newly installed binaries are available

    log "Setting python@3.14.0 as the global default..."
    mise use --global python@3.14.0
}

main() {
    configure_mise "$@"
}

main "$@"
