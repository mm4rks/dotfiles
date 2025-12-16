#!/bin/bash
#
# user_init.sh: Automated setup for a HackTheBox Parrot instance.
#
# This script is designed to be idempotent and non-interactive.
#
# Prerequisites:
# 1. Clone the dotfiles repository to '~/my_data/dotfiles'.
#    git clone <your-repo-url> ~/my_data/dotfiles
# 2. Place this script in '~/my_data/dotfiles/user_init.sh'.
# 3. Create a symlink for easy access:
#    ln -s ~/my_data/dotfiles/user_init.sh ~/my_data/user_init
# 4. EDIT the SSH_PUBLIC_KEY variable below with your actual public SSH key.
#

set -eo pipefail # Exit on error and on pipe failures

# --- Configuration ---
# Resolve the DOTFILES_DIR, following symlinks to find the script's true location.
SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
DOTFILES_DIR=$(dirname "$SCRIPT_PATH")

# !!! IMPORTANT !!!
# Replace the placeholder with your actual public SSH key.
SSH_PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKcqyUBUO957MzQiG8Mx0RovRLy3b/rqtNk+heyHN083 mm4rks@htb"
SSH_TARGET_USER="$USER"

# --- Packages ---
REQUIRED_APT_PACKAGES=(
    curl git unzip stow jq make cmake
    zsh-syntax-highlighting zsh-autosuggestions command-not-found
    ripgrep tmux python3 python3-pip python3-venv xclip bat pipx
    fd-find openssh-server zsh
)

PACKAGES_TO_STOW=(
    "zsh"
    "tmux"
    "git"
    "nvim"
)

# --- Neovim Configuration ---
NVIM_INSTALL_DIR="$HOME/.local/bin"
NVIM_APPIMAGE_PATH="$NVIM_INSTALL_DIR/nvim"
NVIM_APPIMAGE_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.appimage"

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

script_exit_handler() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo -e "\n${ERROR} Script exited prematurely with status ${exit_code}."
    fi
}
trap script_exit_handler EXIT

# --- Installation Functions ---

install_required_packages() {
    echo -e "\n${STEP} Updating package list and installing required packages..."
    sudo apt-get update -q
    if ! sudo apt-get install -q -y "${REQUIRED_APT_PACKAGES[@]}"; then
        echo -e "${ERROR} Failed to install some required packages with apt-get. Please check the output above."
        exit 1
    fi
    echo -e "${INFO} Required APT packages installed."
}

create_symlinks() {
    echo -e "\n${STEP} Creating symlinks for tools..."
    mkdir -p "$HOME/.local/bin"
    
    # Symlink for fdfind -> fd
    if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
        if [ ! -f "$HOME/.local/bin/fd" ]; then
            ln -s "$(which fdfind)" "$HOME/.local/bin/fd"
            echo -e "${INFO} Symlinked fdfind to fd in ~/.local/bin/"
        fi
    fi
    
    # Symlink for batcat -> bat
    if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
        if [ ! -f "$HOME/.local/bin/bat" ]; then
            ln -s "$(which batcat)" "$HOME/.local/bin/bat"
            echo -e "${INFO} Symlinked batcat to bat in ~/.local/bin/"
        fi
    fi
}


install_fzf_from_github() {
    if command -v fzf &>/dev/null; then
        echo -e "${INFO} fzf is already installed. Skipping."
        return 0
    fi

    echo -e "\n${STEP} Installing fzf..."

    local TEMP_DIR
    TEMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TEMP_DIR"' RETURN # Cleanup on function return

    local FZF_LATEST_URL
    FZF_LATEST_URL=$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest | jq -r '.assets[] | select(.name | endswith("linux_amd64.tar.gz")) | .browser_download_url')

    if [ -z "$FZF_LATEST_URL" ]; then
        echo -e "${WARN} Could not find the latest fzf release URL. Skipping installation."
        return 1
    fi

    if ! curl --fail --location -o "${TEMP_DIR}/fzf.tar.gz" "$FZF_LATEST_URL"; then
        echo -e "${WARN} Failed to download fzf. Skipping installation."
        return 1
    fi

    if ! tar -xzf "${TEMP_DIR}/fzf.tar.gz" -C "$TEMP_DIR"; then
        echo -e "${WARN} Failed to extract fzf. Skipping installation."
        return 1
    fi

    if ! sudo mv "${TEMP_DIR}/fzf" /usr/local/bin/; then
        echo -e "${WARN} Failed to move fzf binary to /usr/local/bin/. Skipping installation."
        return 1
    fi

    echo -e "${INFO} fzf installed successfully."
    return 0
}

install_neovim() {
    if command -v nvim &>/dev/null; then
        echo -e "${INFO} Neovim is already installed at '$(command -v nvim)''. Skipping installation."
        return
    fi
    
    echo -e "\n${STEP} Installing Neovim..."
    mkdir -p "$NVIM_INSTALL_DIR"
    curl --fail --location -o "$NVIM_APPIMAGE_PATH" "$NVIM_APPIMAGE_URL"
    chmod u+x "$NVIM_APPIMAGE_PATH"
    echo -e "${INFO} Neovim installed to ${NVIM_APPIMAGE_PATH}"
}

install_pipx_tldr() {
    if ! command -v pipx &>/dev/null; then
        echo -e "${ERROR} pipx is not installed. Please add 'pipx' to REQUIRED_APT_PACKAGES."
        return 1
    fi

    pipx ensurepath # Ensure pipx path is in PATH

    if command -v tldr &>/dev/null; then
        echo -e "${INFO} tldr is already installed. Skipping."
        return 0
    fi
    
    echo -e "\n${STEP} Installing tldr with pipx..."
    if ! pipx install tldr; then
        echo -e "${WARN} Failed to install tldr with pipx."
        return 1
    fi
    echo -e "${INFO} tldr installed."
}

stow_dotfiles() {
    echo -e "\n${STEP} Stowing dotfiles..."

    # Back up existing .zshrc if it's a real file to prevent stow conflicts.
    if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
        echo -e "${INFO} Backing up existing .zshrc to .zshrc.bak..."
        mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
    fi

    for pkg in "${PACKAGES_TO_STOW[@]}"; do
        local source_dir="${DOTFILES_DIR}/${pkg}"
        if [ ! -d "$source_dir" ]; then
            echo -e "${WARN} Package '${pkg}' not found in dotfiles directory. Skipping."
            continue
        fi

        echo -e "${INFO} Stowing '${pkg}'..."
        if ! stow_output=$(stow --dir="$DOTFILES_DIR" --target="$HOME" --restow "$pkg" 2>&1); then
            echo -e "${WARN} Failed to stow '${pkg}'. It might be already stowed or have conflicts."
            echo -e "${YELLOW}Stow output:${NC}\n$stow_output"
        else
            echo -e "${INFO} '${pkg}' stowed successfully."
        fi
    done
}

configure_ssh() {
    echo -e "\n${STEP} Configuring SSH..."

    if [ -z "$SSH_TARGET_USER" ] || [[ "$SSH_PUBLIC_KEY" == "ssh-rsa AAAA..."* ]]; then
        echo -e "${ERROR} Target username is not set or SSH_PUBLIC_KEY is still a placeholder. Skipping SSH hardening."
        return 1
    fi

    local SSH_CONFIG_FILE="/etc/ssh/sshd_config"
    local USER_HOME
    USER_HOME=$(getent passwd "$SSH_TARGET_USER" | cut -d: -f6 || true)
    local SSH_DIR="$USER_HOME/.ssh"
    local AUTH_KEYS_FILE="$SSH_DIR/authorized_keys"

    if [ -z "$USER_HOME" ]; then
        echo -e "${ERROR} User '$SSH_TARGET_USER' does not exist. Skipping SSH hardening."
        return 1
    fi
    echo -e "${INFO} Configuring SSH for user: $SSH_TARGET_USER"
    sudo mkdir -p "$SSH_DIR"
    sudo touch "$AUTH_KEYS_FILE"

    if ! sudo grep -q -F "$SSH_PUBLIC_KEY" "$AUTH_KEYS_FILE"; then
        echo "$SSH_PUBLIC_KEY" | sudo tee -a "$AUTH_KEYS_FILE" > /dev/null
        echo -e "${INFO} Public key added to $AUTH_KEYS_FILE."
    else
        echo -e "${INFO} Public key already exists in $AUTH_KEYS_FILE."
    fi

    sudo chown -R "$SSH_TARGET_USER:$SSH_TARGET_USER" "$SSH_DIR"
    sudo chmod 700 "$SSH_DIR"
    sudo chmod 600 "$AUTH_KEYS_FILE"
    echo -e "${INFO} SSH directory permissions set."

    set_sshd_config_sudo() {
        local key="$1"
        local value="$2"
        if sudo grep -qE "^\s*#?\s*$key\s+" "$SSH_CONFIG_FILE"; then
            sudo sed -i -E "s/^\s*#?\s*$key\s+.*/$key $value/" "$SSH_CONFIG_FILE"
        else
            echo "$key $value" | sudo tee -a "$SSH_CONFIG_FILE" > /dev/null
        fi
    }

    echo -e "${INFO} Applying sshd_config modifications..."
    set_sshd_config_sudo "PubkeyAuthentication" "yes"
    set_sshd_config_sudo "PasswordAuthentication" "no"
    set_sshd_config_sudo "PermitRootLogin" "no"
    set_sshd_config_sudo "ChallengeResponseAuthentication" "no"

    echo -e "${INFO} Restarting sshd service..."
    if sudo systemctl restart ssh; then
        echo -e "${INFO} SSH configuration applied successfully."
    else
        echo -e "${ERROR} Failed to restart sshd service. Please check manually."
        return 1
    fi
}

change_shell_to_zsh() {
    if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$(which zsh)" ]; then
        echo -e "\n${STEP} Changing default shell to zsh for $USER..."
        if sudo chsh -s "$(which zsh)" "$USER"; then
            echo -e "${INFO} Default shell changed to zsh. Please log out and log back in for the change to take effect."
        else
            echo -e "${ERROR} Failed to change default shell."
            return 1
        fi
    else
        echo -e "${INFO} Default shell is already zsh."
    fi
}


# --- Main Script Execution ---
main() {
    if ! sudo -v; then
        echo -e "${ERROR} This script requires sudo privileges. Please run it with a user that has sudo access."
        exit 1
    fi

    install_required_packages
    create_symlinks
    install_fzf_from_github
    install_neovim
    install_pipx_tldr
    configure_ssh
    stow_dotfiles
    change_shell_to_zsh

    echo -e "\n${GREEN}--- Setup Complete ---${NC}"
    echo -e "${YELLOW}Next Steps:${NC}"
    echo -e "1. ${YELLOW}IMPORTANT:${NC} Log out and log back in to apply shell changes."
    echo -e "2. Run \"${BLUE}nvim${NC}\" and then execute \":PackerSync\" to install Neovim plugins."
}

main
