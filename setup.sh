#!/bin/bash

set -eo pipefail # Exit on error and on pipe failures

script_exit_handler() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo -e "\n${ERROR} Script exited prematurely with status ${exit_code}."
    fi
}
trap script_exit_handler EXIT

# --- Configuration ---
DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +"%Y%m%d-%H%M%S")"
# These packages will always be stowed. 'nvim' is handled conditionally.
CORE_PACKAGES_TO_STOW=(
    "zsh"
    "tmux"
    "git"
    "zsh_plugins"
    "dockerfiles"
)

# --- Neovim Configuration ---
NVIM_INSTALL_DIR="$HOME/.local/bin"
NVIM_APPIMAGE_PATH="$NVIM_INSTALL_DIR/nvim"
NVIM_APPIMAGE_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage"

# --- Font Configuration ---
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/FiraMono.zip"
FONT_NAME="FiraMono"
FONT_INSTALL_DIR="${HOME}/.local/share/fonts"

# --- Colors and Logging ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INFO="[${GREEN}INFO${NC}]"
WARN="[${YELLOW}WARN${NC}]"
ERROR="[${RED}ERROR${NC}]"
STEP="[${BLUE}STEP${NC}]"


# A generic function to ask the user a yes/no question.
ask_to_proceed() {
    local prompt_message="$1"
    read -p "$(echo -e ${STEP}) ${prompt_message} (y/N): " -r answer
    answer=${answer:-n}
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        return 0 # Success (yes)
    else
        return 1 # Failure (no)
    fi
}

install_required_packages() {
    echo -e "\n${STEP} Updating package list and installing required packages..."
    local required_packages=(
        curl git unzip fontconfig stow fzf pipx
        zsh-syntax-highlighting zsh-autosuggestions command-not-found
        ripgrep
    )
    sudo apt-get update -q
    sudo apt-get install -q "${required_packages[@]}"
}

install_nerd_font() {
    if [ -d "${FONT_INSTALL_DIR}/${FONT_NAME}" ]; then
        echo -e "${INFO} ${FONT_NAME} Nerd Font is already installed. Skipping."
        return
    fi

    local TEMP_DIR
    TEMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TEMP_DIR"' EXIT

    curl --fail --location -o "${TEMP_DIR}/font.zip" "${FONT_URL}"
    mkdir -p "${FONT_INSTALL_DIR}/${FONT_NAME}"
    unzip -q -o "${TEMP_DIR}/font.zip" -d "${FONT_INSTALL_DIR}/${FONT_NAME}"
    echo -e "${INFO} Updating font cache..."
    fc-cache -fv >/dev/null
    echo -e "${INFO} ${FONT_NAME} Nerd Font installed successfully."
}

install_neovim() {
    if command -v nvim &>/dev/null; then
        echo -e "${INFO} Neovim is already installed at '$(command -v nvim)'. Skipping installation."
        return
    fi
    
    mkdir -p "$NVIM_INSTALL_DIR"
    curl --fail --location -o "$NVIM_APPIMAGE_PATH" "$NVIM_APPIMAGE_URL"
    chmod u+x "$NVIM_APPIMAGE_PATH"
    echo -e "${INFO} Neovim installed to ${NVIM_APPIMAGE_PATH}"
    echo -e "${WARN} Please ensure '${NVIM_INSTALL_DIR}' is in your PATH."
}

setup_argcomplete() {
    echo -e "\n${STEP} Setting up Python Argcomplete..."
    if ! command -v pipx &>/dev/null; then
        echo -e "${ERROR} pipx is not installed. This is required."
        return 1
    fi
    
    # Use -q for quiet install
    pipx install argcomplete -q
    if pipx run activate-global-python-argcomplete &>/dev/null; then
        echo -e "${INFO} Argcomplete activated."
    else
        echo -e "${ERROR} Failed to activate global completions."
        return 1
    fi
}

# --- stow package, backup existing on conflict
stow_package() {
    local pkg="$1"
    local backed_up_in_this_run=false

    if [ -z "$pkg" ]; then
        echo -e "${WARN} stow_package called with empty package name. Skipping."
        return 1
    fi

    local source_dir="${DOTFILES_DIR}/${pkg}"
    if [ ! -d "$source_dir" ]; then
        echo -e "\n${WARN} Package '${pkg}' not found in dotfiles directory. Skipping."
        return 1
    fi

    local stow_output
    stow_output=$(stow --dir="$DOTFILES_DIR" --target="$HOME" --simulate --verbose=2 "$pkg" 2>&1 || true)

    if echo "$stow_output" | grep -q 'over existing target'; then
        echo -e "${WARN} Conflicts detected for package: ${YELLOW}${pkg}${NC}. Backing up existing files..."
        if ! $backed_up_in_this_run; then
            mkdir -p "$BACKUP_DIR"
            backed_up_in_this_run=true
        fi

        local conflicts
        conflicts=$(echo "$stow_output" | grep 'over existing target' | sed 's/.*over existing target //; s/ .*//' | sort -u)

        for conflict_file in $conflicts; do
            local full_path="${HOME}/${conflict_file}"
            echo -e "${INFO} Backing up '${conflict_file}'..."
            mkdir -p "$(dirname "${BACKUP_DIR}/${conflict_file}")"
            mv "$full_path" "${BACKUP_DIR}/${conflict_file}"
        done
    fi

    echo -e "${INFO} Stowing '${pkg}'..."
    if ! stow --dir="$DOTFILES_DIR" --target="$HOME" --restow "$pkg"; then
        echo -e "${ERROR}Failed to stow '${pkg}'.${NC}"
    fi

    if $backed_up_in_this_run; then
        echo -e "${YELLOW}Backed up files for '${pkg}' are in:${NC} ${BLUE}${BACKUP_DIR}${NC}"
    fi
}

# --- Main Script Execution ---
main() {
    install_required_packages
    setup_argcomplete

    if ask_to_proceed "Do you want to install FiraMono Nerd Font?"; then
        install_nerd_font
    fi

    if ask_to_proceed "Do you want to install Neovim and set up LazyVim?"; then
        install_neovim
        stow_package "nvim" # Conditionally stow the nvim package
    fi

    # Stow all the core, unconditional packages
    echo -e "\n${STEP} Stowing core dotfiles..."
    for pkg in "${CORE_PACKAGES_TO_STOW[@]}"; do
        stow_package "$pkg"
    done

    echo -e "\n\n${GREEN}--- Setup Complete ---${NC}"
    echo -e "\n${YELLOW}Next Steps:${NC}"
    echo -e "1. ${YELLOW}IMPORTANT:${NC} Open your terminal's settings and change its font to 'FiraMono Nerd Font' (if installed)."
    echo -e "2. Restart your terminal to apply all changes."
    echo -e "3. If you installed Neovim, run \`${BLUE}nvim${NC}\`. LazyVim will automatically install plugins on the first run."
}

main
