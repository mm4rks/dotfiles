#!/bin/bash

set -eo pipefail # Exit on error and on pipe failures

# --- Neovim Configuration ---
NVIM_INSTALL_DIR="$HOME/.local/bin"
NVIM_APPIMAGE_PATH="$NVIM_INSTALL_DIR/nvim"
NVIM_APPIMAGE_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage"
NVIM_CONFIG_DIR="$HOME/.config/nvim"

# --- Font Configuration ---
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/FiraMono.zip"
FONT_NAME="FiraMono"
FONT_INSTALL_DIR="${HOME}/.local/share/fonts"

# --- Colors and Logging ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

INFO="[${GREEN}INFO${NC}]"
WARN="[${YELLOW}WARN${NC}]"
ERROR="[${RED}ERROR${NC}]"
STEP="[${BLUE}STEP${NC}]"

install_required_packages() {
    echo -e "\n${STEP} Checking for required system packages..."
    local required_packages=(
        "curl"
        "git"
        "unzip"
        "fontconfig"
        "stow"
        "fzf"
        "zsh-syntax-highlighting"
        "zsh-autosuggestions"
        "command-not-found"
    )
    
    local packages_to_install=()

    # Check which packages are actually missing.
    for pkg in "${required_packages[@]}"; do
        if ! dpkg -l | grep -q "^ii.* ${pkg} "; then
            packages_to_install+=("$pkg")
        fi
    done

    # Only run apt if there are packages to install.
    if [ ${#packages_to_install[@]} -gt 0 ]; then
        echo -e "${INFO} The following packages will be installed: ${packages_to_install[*]}"
        sudo apt-get update
        sudo apt-get install -y "${packages_to_install[@]}"
        echo -e "${INFO} Packages installed successfully."
    else
        echo -e "${INFO} All required packages are already installed."
    fi
}

# Function to install the specified Nerd Font if not already present.
install_nerd_font() {
    echo -e "\n${STEP} Checking for ${FONT_NAME} Nerd Font..."
    # Idempotency check
    if [ -d "${FONT_INSTALL_DIR}/${FONT_NAME}" ] && [ -n "$(find "${FONT_INSTALL_DIR}/${FONT_NAME}" -name '*FiraMono*NerdFont*' -print -quit)" ]; then
        echo -e "${INFO} ${FONT_NAME} Nerd Font is already installed. Skipping."
        return
    fi
    
    echo -e "${INFO} ${FONT_NAME} Nerd Font not found. Starting installation..."
    local TEMP_DIR
    TEMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TEMP_DIR"' EXIT

    echo -e "${INFO} Downloading font from ${FONT_URL}..."
    if ! curl --fail --location -o "${TEMP_DIR}/font.zip" "${FONT_URL}"; then
        echo -e "${ERROR} Failed to download font."
        exit 1
    fi

    mkdir -p "${FONT_INSTALL_DIR}/${FONT_NAME}"
    unzip -q -o "${TEMP_DIR}/font.zip" -d "${FONT_INSTALL_DIR}/${FONT_NAME}"

    echo -e "${INFO} Updating font cache..."
    fc-cache -fv > /dev/null
    echo -e "${INFO} ${FONT_NAME} Nerd Font installed successfully."
}

# Function to install the latest stable Neovim AppImage if not already present.
install_neovim() {
    echo -e "\n${STEP} Checking for Neovim installation..."
    # Check both our target path and the system path
    if command -v nvim &> /dev/null; then
        echo -e "${INFO} Neovim is already installed at '$(command -v nvim)'. Skipping installation."
        return
    fi

    echo -e "${INFO} Neovim not found. Starting installation..."
    mkdir -p "$NVIM_INSTALL_DIR"
    
    echo -e "${INFO} Downloading Neovim AppImage..."
    if ! curl --fail --location -o "$NVIM_APPIMAGE_PATH" "$NVIM_APPIMAGE_URL"; then
        echo -e "${ERROR} Failed to download Neovim AppImage."
        exit 1
    fi
    
    chmod u+x "$NVIM_APPIMAGE_PATH"
    echo -e "${INFO} Neovim installed successfully to ${NVIM_APPIMAGE_PATH}"
    echo -e "${WARN} Please ensure '${NVIM_INSTALL_DIR}' is in your PATH."
}

# Function to set up LazyVim using stow.
setup_lazyvim_stow() {
    echo -e "\n${STEP} Checking for LazyVim configuration..."
    
    # Get the directory where the script is located
    local SCRIPT_DIR
    SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

    if [ ! -d "${SCRIPT_DIR}/nvim/.config/nvim" ]; then
        echo -e "${ERROR} LazyVim config not found at '${SCRIPT_DIR}/nvim/.config/nvim'."
        echo -e "${WARN} Ensure the script is in your dotfiles root and the config exists."
        return 1
    fi
    
    if [ -d "$NVIM_CONFIG_DIR" ] || [ -L "$NVIM_CONFIG_DIR" ]; then
        if [ -L "$NVIM_CONFIG_DIR" ] && [[ "$(readlink "$NVIM_CONFIG_DIR")" == *"${SCRIPT_DIR}/nvim/.config/nvim"* ]]; then
            echo -e "${INFO} LazyVim config is already stowed. Skipping."
            return
        fi

        local backup_dir="${NVIM_CONFIG_DIR}.bak.$(date +"%Y%m%d-%H%M%S")"
        echo -e "${WARN} Existing Neovim config found. Backing it up to ${backup_dir}"
        mv "$NVIM_CONFIG_DIR" "$backup_dir"
    fi
    
    echo -e "${INFO} Stowing LazyVim configuration..."
    # Stow from the script's directory, target the home directory, and select the 'nvim' package
    if stow -d "$SCRIPT_DIR" -t "$HOME" nvim; then
        echo -e "${INFO} LazyVim stowed successfully."
    else
        echo -e "${ERROR} Failed to stow LazyVim config."
        echo -e "${WARN} Please check for file conflicts and try running 'stow nvim' manually from '${SCRIPT_DIR}'."
        return 1
    fi
}

# Function to handle the entire Neovim and LazyVim setup process.
handle_neovim_setup() {
    echo "" # Add a newline for better formatting
    read -p "$(echo -e ${STEP}) Do you want to install Neovim and set up LazyVim? (y/N): " -r answer
    # Default to 'n' if the user just presses Enter
    answer=${answer:-n}
    
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        install_neovim
        setup_lazyvim_stow
    else
        echo -e "${INFO} Skipping Neovim and LazyVim setup."
    fi
}

# Function to handle the entire Neovim and LazyVim setup process.
handle_nerdfont_setup() {
    echo "" # Add a newline for better formatting
    read -p "$(echo -e ${STEP}) Do you want to install NerdFont? (y/N): " -r answer
    # Default to 'n' if the user just presses Enter
    answer=${answer:-n}
    
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        install_nerd_font
    else
        echo -e "${INFO} Skipping NerdFont setup."
    fi
}

# --- Main Script Execution ---
main() {
    check_dependencies
    install_apt_packages
    handle_nerdfont_setup
    handle_neovim_setup
    
    echo -e "\n\n${GREEN}--- System Configuration Verified ---${NC}"
    echo -e "All components are installed and configured."
    echo -e "\n${YELLOW}Next Steps (if this is your first time running):${NC}"
    echo -e "1. ${YELLOW}IMPORTANT:${NC} Open your terminal's settings and change its font to 'FiraMono Nerd Font'."
    echo -e "2. Restart your terminal to apply changes (e.g., Zsh plugins)."
    echo -e "3. If you installed Neovim, run \`${BLUE}nvim${NC}\`. LazyVim will automatically install plugins on the first run."
}

main
