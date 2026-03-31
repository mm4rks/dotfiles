#!/bin/bash
set -euo pipefail

PROFILES=" $* "
REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# Helper log functions if not sourced from lib.sh
log() { echo -e "\033[0;32m[INFO]\033[0m $1"; }
warn() { echo -e "\033[0;33m[WARN]\033[0m $1"; }
error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; exit 1; }

if [[ "$PROFILES" == *" guest "* ]]; then
    echo "[INFO] Entering Guest/Sandbox Mode..."
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

echo "[INFO] Starting Dotfiles Setup..."
echo "[INFO] Profiles selected:${PROFILES:- default}"

# 1. System Base (Elevated)
if [[ "$PROFILES" != *" guest "* ]]; then
    echo "[INFO] --- Phase 1: System Base (Elevated) ---"
    sudo "${REPO_DIR}/scripts/install_base_deps.sh" || { echo "[ERROR] Base dependencies installation failed."; exit 1; }
    # Note: install_docker.sh is now handled by opencode if missing
    # but we can still call it here for an initial clean install.
    sudo "${REPO_DIR}/scripts/install_docker.sh" || { echo "[ERROR] Docker installation failed."; exit 1; }
    sudo "${REPO_DIR}/scripts/install_mise.sh" || { echo "[ERROR] Mise installation failed."; exit 1; }
    sudo "${REPO_DIR}/scripts/install_nerd_font.sh" || { echo "[ERROR] Nerd font installation failed."; exit 1; }
else
    echo "[INFO] --- Skipping Phase 1 (guest profile) ---"
fi

# Fix permissions on ~/.local if it was created by root processes
if [[ "$PROFILES" != *" guest "* ]]; then
    sudo chown -R "$(whoami)":"$(whoami)" "$HOME/.local" 2>/dev/null || true
    # Ensure zsh is default shell
    sudo chsh -s "$(which zsh)" "$(whoami)" 2>/dev/null || true
fi

# 2. User Environment
echo "[INFO] --- Phase 2: User Environment ---"
if [[ "$PROFILES" == *" guest "* ]]; then
    "${REPO_DIR}/scripts/install_mise.sh" || { echo "[ERROR] Mise installation failed."; exit 1; }
fi
"${REPO_DIR}/scripts/configure_mise.sh" "$@" || { echo "[ERROR] Mise configuration failed."; exit 1; }

# Important: Activate mise in the current shell so subsequent scripts (like sync_nvim.sh) can find their tools
if command -v mise &>/dev/null; then
    eval "$(mise activate bash)"
    log "Mise activated for current session."
elif [ -f "$HOME/.local/bin/mise" ]; then
    eval "$("$HOME/.local/bin/mise" activate bash)"
    log "Mise (local) activated for current session."
fi

if [[ "$PROFILES" != *" guest "* ]]; then
    "${REPO_DIR}/scripts/install_opencode.sh" || { echo "[ERROR] OpenCode installation failed."; exit 1; }
    "${REPO_DIR}/scripts/stow_dotfiles.sh" || { echo "[ERROR] Dotfiles stowing failed."; exit 1; }
fi
"${REPO_DIR}/scripts/sync_nvim.sh" || { echo "[ERROR] Neovim sync failed."; exit 1; }

# 3. Profile: pwn
if [[ "$PROFILES" == *" pwn "* ]]; then
    echo "[INFO] --- Phase 3: Profile 'pwn' ---"
    sudo "${REPO_DIR}/scripts/install_bloodhound.sh"
    
    # We must ensure pipx is available in the current shell for user scripts
    eval "$(mise activate bash)"
    pipx ensurepath
    
    "${REPO_DIR}/scripts/install_netexec.sh"
    "${REPO_DIR}/scripts/install_powerview.sh"
    "${REPO_DIR}/scripts/install_certipy.sh"
fi

# 4. Profile: rev
if [[ "$PROFILES" == *" rev "* ]]; then
    echo "[INFO] --- Phase 4: Profile 'rev' ---"
    sudo "${REPO_DIR}/scripts/install_joern.sh"
    sudo "${REPO_DIR}/scripts/install_ghidra.sh"
fi

# 5. Profile: ssh
if [[ "$PROFILES" == *" ssh "* ]]; then
    echo "[INFO] --- Phase 5: Profile 'ssh' ---"
    sudo "${REPO_DIR}/scripts/harden_ssh.sh"
fi

echo "[INFO] Dotfiles Setup Complete!"
