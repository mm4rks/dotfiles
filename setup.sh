#!/bin/bash
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# Load common library
source "${REPO_DIR}/scripts/lib.sh"

MODE=""
PROFILES=" "

usage() {
    cat <<EOF
Usage: ./setup.sh [persistent|guest] [headless] [pwn] [ssh]

Modes (prompted for if omitted):
  persistent  Full install: system packages and tools via sudo, dotfiles stowed into \$HOME.
  guest       Sandboxed: no sudo, nothing written to \$HOME. Installs the terminal
              tools and nvim plugins into <repo>/.guest/. Enter with 'source activate.sh'.

Profiles (persistent mode only):
  headless    Skip the Nerd Font install.
  pwn         BloodHound, NetExec, PowerView, Certipy.
  ssh         Install and harden openssh-server (requires an authorized_keys file).
EOF
}

parse_args() {
    local arg
    for arg in "$@"; do
        case "$arg" in
            persistent|guest)
                if [ -n "$MODE" ] && [ "$MODE" != "$arg" ]; then
                    error "Conflicting modes: '${MODE}' and '${arg}'."
                fi
                MODE="$arg"
                ;;
            headless|pwn|ssh) PROFILES+="${arg} " ;;
            -h|--help) usage; exit 0 ;;
            *) usage >&2; error "Unknown argument: ${arg}" ;;
        esac
    done
}

prompt_mode() {
    if [ ! -t 0 ]; then
        error "No mode given and stdin is not a terminal. Pass 'persistent' or 'guest'."
    fi

    local answer
    echo "Select install mode:"
    echo "  [p] persistent - sudo, system packages, dotfiles stowed into \$HOME"
    echo "  [g] guest      - no sudo, sandboxed in ${REPO_DIR}/.guest"
    while true; do
        read -r -p "Mode [p/g]: " answer
        case "${answer,,}" in
            p|persistent) MODE="persistent"; return 0 ;;
            g|guest) MODE="guest"; return 0 ;;
            *) echo "Please answer 'p' or 'g'." ;;
        esac
    done
}

has_profile() {
    [[ "$PROFILES" == *" $1 "* ]]
}

setup_guest() {
    if has_profile pwn || has_profile ssh; then
        error "Profiles 'pwn' and 'ssh' need root and are not available in guest mode."
    fi

    # Guest mode cannot install system packages; the host must provide these.
    local missing=() cmd
    for cmd in curl tar xz git zsh; do
        command_exists "$cmd" || missing+=("$cmd")
    done
    if [ ${#missing[@]} -gt 0 ]; then
        error "Missing host prerequisites: ${missing[*]}. Ask the host admin to install them."
    fi

    log "--- Guest Mode: sandboxed in ${REPO_DIR}/.guest ---"
    # shellcheck source=activate.sh
    source "${REPO_DIR}/activate.sh"

    "${REPO_DIR}/scripts/install_terminal_tools.sh"
    "${REPO_DIR}/scripts/sync_nvim.sh"

    log "Security tooling (Ghidra, Joern, pipx tools, ...) is skipped in guest mode."
    log "Guest setup complete. Enter it with: source ${REPO_DIR}/activate.sh && exec zsh"
}

setup_persistent() {
    # 1. System Base (Elevated)
    log "--- Phase 1: System Base (Elevated) ---"
    sudo "${REPO_DIR}/scripts/install_base_deps.sh"
    sudo "${REPO_DIR}/scripts/install_docker.sh"
    if ! has_profile headless; then
        sudo "${REPO_DIR}/scripts/install_nerd_font.sh"
    fi

    # Fix permissions on ~/.local if it was created by root processes
    sudo chown -R "$(id -un)":"$(id -gn)" "$HOME/.local" 2>/dev/null || true
    # Ensure zsh is default shell
    sudo chsh -s "$(command -v zsh)" "$(id -un)" 2>/dev/null || true

    # 2. User Environment
    log "--- Phase 2: User Environment ---"
    "${REPO_DIR}/scripts/install_terminal_tools.sh"
    # Ensure ~/.local/bin is on PATH for subsequent scripts (like sync_nvim.sh)
    export PATH="${HOME}/.local/bin:${PATH}"

    "${REPO_DIR}/scripts/stow_dotfiles.sh"
    "${REPO_DIR}/scripts/sync_nvim.sh"

    # 3. Default Tools
    log "--- Phase 3: Default Tools ---"
    sudo "${REPO_DIR}/scripts/install_ghidra.sh"
    sudo "${REPO_DIR}/scripts/install_joern.sh"
    "${REPO_DIR}/scripts/install_jadx.sh"
    "${REPO_DIR}/scripts/install_apktool.sh"
    "${REPO_DIR}/scripts/install_trivy.sh"
    "${REPO_DIR}/scripts/install_dependency_check.sh"

    pipx ensurepath
    "${REPO_DIR}/scripts/install_rev_pipx_tools.sh"

    # 4. Profile: pwn
    if has_profile pwn; then
        log "--- Phase 4: Profile 'pwn' ---"
        sudo "${REPO_DIR}/scripts/install_bloodhound.sh"
        "${REPO_DIR}/scripts/install_netexec.sh"
        "${REPO_DIR}/scripts/install_powerview.sh"
        "${REPO_DIR}/scripts/install_certipy.sh"
    fi

    # 5. Profile: ssh
    if has_profile ssh; then
        log "--- Phase 5: Profile 'ssh' ---"
        sudo "${REPO_DIR}/scripts/harden_ssh.sh"
    fi

    log "Dotfiles Setup Complete!"
}

main() {
    parse_args "$@"
    [ -n "$MODE" ] || prompt_mode

    log "Starting Dotfiles Setup (mode: ${MODE}, profiles:${PROFILES% })..."
    if [ "$MODE" = "guest" ]; then
        setup_guest
    else
        setup_persistent
    fi
}

main "$@"
