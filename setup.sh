#!/bin/bash
set -euo pipefail

PROFILES=" $* "
REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# Load common library
source "${REPO_DIR}/scripts/lib.sh"

if [[ "$PROFILES" == *" guest "* ]]; then
    log "Entering Guest/Sandbox Mode..."
    export ZDOTDIR="${REPO_DIR}/zsh"
    export XDG_CONFIG_HOME="${REPO_DIR}/config"
    mkdir -p "${XDG_CONFIG_HOME}"
    # Ensure ~/.local/bin is in path for tool discovery
    export PATH="${HOME}/.local/bin:${PATH}"
    # Link nvim config into our sandboxed XDG_CONFIG_HOME
    if [ ! -L "${XDG_CONFIG_HOME}/nvim" ]; then
        ln -sf "${REPO_DIR}/nvim/.config/nvim" "${XDG_CONFIG_HOME}/nvim"
    fi
fi

log "Starting Dotfiles Setup..."
log "Profiles selected:${PROFILES:- default}"

# 1. System Base (Elevated)
log "--- Phase 1: System Base (Elevated) ---"
sudo "${REPO_DIR}/scripts/install_base_deps.sh"
sudo "${REPO_DIR}/scripts/install_docker.sh"
sudo "${REPO_DIR}/scripts/install_nerd_font.sh"

# Fix permissions on ~/.local if it was created by root processes
sudo chown -R "$(whoami)":"$(whoami)" "$HOME/.local" 2>/dev/null || true
# Ensure zsh is default shell
if [[ "$PROFILES" != *" guest "* ]]; then
    sudo chsh -s "$(which zsh)" "$(whoami)" 2>/dev/null || true
fi

# 2. User Environment
log "--- Phase 2: User Environment ---"
"${REPO_DIR}/scripts/install_terminal_tools.sh"
# Ensure ~/.local/bin is on PATH for subsequent scripts (like sync_nvim.sh)
export PATH="${HOME}/.local/bin:${PATH}"

if [[ "$PROFILES" != *" guest "* ]]; then
    "${REPO_DIR}/scripts/stow_dotfiles.sh"
fi
"${REPO_DIR}/scripts/sync_nvim.sh"

# 3. Profile: pwn
if [[ "$PROFILES" == *" pwn "* ]]; then
    log "--- Phase 3: Profile 'pwn' ---"
    sudo "${REPO_DIR}/scripts/install_bloodhound.sh"

    pipx ensurepath

    "${REPO_DIR}/scripts/install_netexec.sh"
    "${REPO_DIR}/scripts/install_powerview.sh"
    "${REPO_DIR}/scripts/install_certipy.sh"
fi

# 4. Profile: rev
if [[ "$PROFILES" == *" rev "* ]]; then
    log "--- Phase 4: Profile 'rev' ---"
    sudo "${REPO_DIR}/scripts/install_joern.sh"
    sudo "${REPO_DIR}/scripts/install_ghidra.sh"
    "${REPO_DIR}/scripts/install_apktool.sh"
    "${REPO_DIR}/scripts/install_jadx.sh"
    "${REPO_DIR}/scripts/install_trivy.sh"
    "${REPO_DIR}/scripts/install_dependency_check.sh"

    pipx ensurepath
    "${REPO_DIR}/scripts/install_rev_pipx_tools.sh"
fi

# 5. Profile: ssh
if [[ "$PROFILES" == *" ssh "* ]]; then
    log "--- Phase 5: Profile 'ssh' ---"
    sudo "${REPO_DIR}/scripts/harden_ssh.sh"
fi

log "Dotfiles Setup Complete!"
