#!/bin/bash
# activate.sh: Enters the sandboxed "Guest Mode" for this dotfiles repo.
# Run with: source ./activate.sh

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

export ZDOTDIR="${REPO_DIR}/zsh"
export XDG_CONFIG_HOME="${REPO_DIR}/config"
export XDG_CACHE_HOME="${REPO_DIR}/cache"
mkdir -p "${XDG_CONFIG_HOME}" "${XDG_CACHE_HOME}"

# Link nvim config into our sandboxed XDG_CONFIG_HOME if missing
if [ ! -L "${XDG_CONFIG_HOME}/nvim" ]; then
    ln -sf "${REPO_DIR}/nvim/.config/nvim" "${XDG_CONFIG_HOME}/nvim"
fi

# Prepend our local bins and mise bins to PATH
export PATH="${HOME}/.local/bin:${PATH}"

# Add tmux alias to use our repo's config
# shellcheck disable=SC2139
alias tmux="tmux -f ${REPO_DIR}/tmux/.tmux.conf"

echo "[INFO] Sandboxed Guest Mode Activated."
echo "[INFO] ZDOTDIR: ${ZDOTDIR}"
echo "[INFO] XDG_CONFIG_HOME: ${XDG_CONFIG_HOME}"
echo "[INFO] Run 'exec zsh' to enter your custom shell."
