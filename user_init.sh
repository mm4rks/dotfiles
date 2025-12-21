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
    "eza"
)

# --- Neovim Configuration ---
NVIM_INSTALL_DIR="$HOME/.local/bin"
NVIM_APPIMAGE_PATH="$NVIM_INSTALL_DIR/nvim"


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
    echo -e "\n${STEP} Updating package list and upgrading system with parrot-upgrade..."
    sudo apt-get update -q
    if ! sudo parrot-upgrade -y; then
        echo -e "${ERROR} Failed to perform full system upgrade with parrot-upgrade. Please check the output above."
        exit 1
    fi
    echo -e "${INFO} System upgraded with parrot-upgrade."
    echo -e "${STEP} Installing required packages..."
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

install_eza_from_github() {
    if command -v eza &>/dev/null; then
        echo -e "${INFO} eza is already installed. Skipping."
        return 0
    fi

    echo -e "\n${STEP} Installing eza from GitHub..."

    local TEMP_DIR
    TEMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TEMP_DIR"' RETURN # Cleanup on function return

    local EZA_LATEST_URL
    EZA_LATEST_URL=$(curl -s https://api.github.com/repos/eza-community/eza/releases/latest | jq -r '.assets[] | select(.name | endswith("x86_64-unknown-linux-gnu.zip")) | .browser_download_url')

    if [ -z "$EZA_LATEST_URL" ]; then
        echo -e "${WARN} Could not find the latest eza release URL. Skipping installation."
        return 1
    fi

    if ! curl --fail --location -o "${TEMP_DIR}/eza.zip" "$EZA_LATEST_URL"; then
        echo -e "${WARN} Failed to download eza. Skipping installation."
        return 1
    fi

    if ! unzip -q "${TEMP_DIR}/eza.zip" -d "$TEMP_DIR"; then
        echo -e "${WARN} Failed to extract eza. Skipping installation."
        return 1
    fi

    if ! sudo mv "${TEMP_DIR}/eza" /usr/local/bin/; then
        echo -e "${WARN} Failed to move eza binary to /usr/local/bin/. Skipping installation."
        return 1
    fi

    echo -e "${INFO} eza installed successfully."
    return 0
}


install_neovim() {
    echo -e "\n${STEP} Installing/updating to the latest Neovim AppImage..."
    
    local latest_url
    latest_url=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest | jq -r '.assets[] | select(.name == "nvim-linux-x86_64.appimage") | .browser_download_url')

    if [ -z "$latest_url" ] || [ "$latest_url" == "null" ]; then
        echo -e "${ERROR} Could not determine the latest Neovim download URL from GitHub API."
        return 1
    fi

    echo -e "${INFO} Downloading Neovim from: $latest_url"
    mkdir -p "$NVIM_INSTALL_DIR"
    if curl --fail --location -o "$NVIM_APPIMAGE_PATH" "$latest_url"; then
        chmod u+x "$NVIM_APPIMAGE_PATH"
        echo -e "${INFO} Neovim installed/updated to ${NVIM_APPIMAGE_PATH}"
        echo -e "${WARN} Make sure '$NVIM_INSTALL_DIR' is at the beginning of your PATH to use this version."
    else
        echo -e "${ERROR} Failed to download Neovim AppImage."
        return 1
    fi
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

install_netexec_with_pipx() {
    if ! command -v pipx &>/dev/null; then
        echo -e "${ERROR} pipx is not installed. Please add 'pipx' to REQUIRED_APT_PACKAGES."
        return 1
    fi

    pipx ensurepath # Ensure pipx path is in PATH

    echo -e "\n${STEP} Installing/Updating NetExec with pipx..."
    if ! pipx install --force "git+https://github.com/Pennyw0rth/NetExec"; then
        echo -e "${WARN} Failed to install NetExec with pipx."
        return 1
    fi
    echo -e "${INFO} NetExec installed/updated."
}

install_pure_prompt_from_github() {
    echo -e "\n${STEP} Installing Pure Prompt from GitHub..."
    local PURE_PROMPT_DIR="$HOME/.zsh/pure"

    if [ -d "$PURE_PROMPT_DIR" ]; then
        echo -e "${INFO} Pure Prompt directory already exists. Assuming it's installed."
        # Optionally, you could add logic here to `git pull` for updates.
        return 0
    fi

    echo -e "${INFO} Cloning Pure Prompt repository..."
    if ! git clone https://github.com/sindresorhus/pure.git "$PURE_PROMPT_DIR"; then
        echo -e "${WARN} Failed to clone Pure Prompt repository."
        return 1
    fi

    echo -e "${INFO} Pure Prompt cloned successfully."
}

install_choose() {
    echo -e "\n${STEP} Installing Rust and 'choose'..."

    # Install Rust (rustup) if cargo is not available
    if ! command -v cargo &>/dev/null; then
        echo -e "${INFO} cargo not found. Installing Rust..."
        # Use -y for non-interactive installation
        if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
            echo -e "${ERROR} Failed to install Rust."
            return 1
        fi
        # Add cargo to PATH for the current script's execution
        source "$HOME/.cargo/env"
    else
        echo -e "${INFO} cargo is already installed."
    fi

    # Install 'choose' using cargo
    if ! command -v choose &>/dev/null; then
        echo -e "${INFO} Installing 'choose' with cargo..."
        if ! cargo install choose; then
            echo -e "${WARN} Failed to install 'choose' with cargo."
            return 1
        fi
        echo -e "${INFO} 'choose' installed successfully."
    else
        echo -e "${INFO} 'choose' is already installed. Skipping."
    fi
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

configure_pure_prompt() {
    echo -e "\n${STEP} Configuring Pure Prompt in ~/.zshrc..."
    local ZSHRC_PATH="$HOME/.zshrc"

    if ! [ -f "$ZSHRC_PATH" ]; then
        echo -e "${WARN} ~/.zshrc not found. Skipping Pure Prompt configuration."
        return 1
    fi

    # Check if prompt pure is already configured
    if ! grep -q "prompt pure" "$ZSHRC_PATH"; then
        echo -e "${INFO} Appending Pure Prompt configuration to ~/.zshrc."
        {
            echo ""
            echo "# --- Pure Prompt Configuration ---"
            echo "fpath+=($HOME/.zsh/pure)"
            echo "autoload -U promptinit; promptinit"
            echo "prompt pure"
            echo ""
            echo "# Fallback prompt if pure prompt fails to load or is not desired"
            echo "if [ \"\${TERM}\" != \"linux\" ] && ! prompt pure &>/dev/null; then"
            echo "    PROMPT='%(?.%F{white}.%F{red})%(#.#.$)%f '"
            echo "    RPROMPT='%F{blue}%~%f'"
            echo "fi"
        } >> "$ZSHRC_PATH"
        echo -e "${INFO} Pure Prompt configured in ~/.zshrc."
    else
        echo -e "${INFO} Pure Prompt already configured in ~/.zshrc. Skipping."
    fi
}

configure_tmux_autostart() {
    echo -e "\n${STEP} Configuring tmux autostart..."
    local ZSH_ENV_PATH="$HOME/.zsh_env.sh"
    
    local TMUX_AUTOSTART_SNIPPET
    TMUX_AUTOSTART_SNIPPET=$(cat <<'EOF'
# Automatically attach to a tmux session on terminal start
if [[ -z "$TMUX" && "$-" == *i* ]]; then
    SESSION_NAME="main"
    tmux new-session -A -s "$SESSION_NAME"
fi
EOF
)

    # Ensure the snippet is in .zsh_env.sh
    if ! grep -q "tmux new-session -A -s" "$ZSH_ENV_PATH" 2>/dev/null; then
        echo -e "${INFO} Adding tmux autostart to ${ZSH_ENV_PATH}."
        echo -e "\n$TMUX_AUTOSTART_SNIPPET" >> "$ZSH_ENV_PATH"
    else
        echo -e "${INFO} tmux autostart already configured in ${ZSH_ENV_PATH}."
    fi
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
    install_eza_from_github
    install_neovim
    install_pipx_tldr
    install_netexec_with_pipx
    install_pure_prompt_from_github
    install_choose
    configure_ssh
    stow_dotfiles
    configure_pure_prompt
    configure_tmux_autostart
    change_shell_to_zsh

    echo -e "\n${GREEN}--- Setup Complete ---${NC}"
    echo -e "1. ${YELLOW}IMPORTANT:${NC} Log out and log back in to apply shell changes."
}

main
