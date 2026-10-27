#!/bin/bash
# activate.sh: Enters the sandboxed "Guest Mode" for this dotfiles repo.
# Run with: source ./activate.sh   (works from bash and zsh)
#
# Everything guest mode writes (configs, caches, shell history, nvim plugins,
# tool binaries) lives under the gitignored <repo>/.guest/ directory.

# shellcheck disable=SC2296  # zsh fallback, never evaluated under bash
REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-${(%):-%x}}")" &>/dev/null && pwd)

export DOTFILES_GUEST_DIR="${REPO_DIR}/.guest"
export DOTFILES_PREFIX="${DOTFILES_GUEST_DIR}/local"
export ZDOTDIR="${REPO_DIR}/zsh"
export XDG_CONFIG_HOME="${DOTFILES_GUEST_DIR}/config"
export XDG_CACHE_HOME="${DOTFILES_GUEST_DIR}/cache"
export XDG_DATA_HOME="${DOTFILES_GUEST_DIR}/data"
export XDG_STATE_HOME="${DOTFILES_GUEST_DIR}/state"
mkdir -p "${XDG_CONFIG_HOME}" "${XDG_CACHE_HOME}" "${XDG_DATA_HOME}" "${XDG_STATE_HOME}" "${DOTFILES_PREFIX}/bin"

# Link repo configs into the sandboxed XDG_CONFIG_HOME if missing
if [ ! -L "${XDG_CONFIG_HOME}/nvim" ]; then
    ln -sfn "${REPO_DIR}/nvim/.config/nvim" "${XDG_CONFIG_HOME}/nvim"
fi
if [ ! -L "${XDG_CONFIG_HOME}/vivid_colors" ]; then
    ln -sf "${REPO_DIR}/vivid/.config/vivid_colors" "${XDG_CONFIG_HOME}/vivid_colors"
fi

# Prepend the sandboxed bin dir to PATH
export PATH="${DOTFILES_PREFIX}/bin:${PATH}"

# Add tmux alias to use our repo's config
# shellcheck disable=SC2139
alias tmux="tmux -f ${REPO_DIR}/tmux/.tmux.conf"

echo "[INFO] Sandboxed Guest Mode Activated."
echo "[INFO] ZDOTDIR: ${ZDOTDIR}"
echo "[INFO] Sandbox: ${DOTFILES_GUEST_DIR}"
echo "[INFO] Run 'exec zsh' to enter your custom shell."
