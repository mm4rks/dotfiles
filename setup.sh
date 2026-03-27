#!/bin/bash
set -euo pipefail

PROFILES=" $* "
REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

echo "[INFO] Starting Dotfiles Setup..."
echo "[INFO] Profiles selected:${PROFILES:- default}"

# 1. System Base (Elevated)
echo "[INFO] --- Phase 1: System Base (Elevated) ---"
sudo "${REPO_DIR}/scripts/install_base_deps.sh"
sudo "${REPO_DIR}/scripts/install_docker.sh"
sudo "${REPO_DIR}/scripts/install_mise.sh"
sudo "${REPO_DIR}/scripts/install_nerd_font.sh"

# Fix permissions on ~/.local if it was created by root processes
sudo chown -R "$(whoami)":"$(whoami)" "$HOME/.local" 2>/dev/null || true
# Ensure zsh is default shell
sudo chsh -s "$(which zsh)" "$(whoami)" 2>/dev/null || true

# 2. User Environment
echo "[INFO] --- Phase 2: User Environment ---"
"${REPO_DIR}/scripts/configure_mise.sh" "$@"
"${REPO_DIR}/scripts/stow_dotfiles.sh"
"${REPO_DIR}/scripts/sync_nvim.sh"

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
