#!/bin/bash
DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +"%Y%m%d-%H%M%S")"

# --- Neovim Configuration ---
NVIM_INSTALL_DIR="$HOME/.local/bin"
NVIM_APPIMAGE_PATH="$NVIM_INSTALL_DIR/nvim"
NVIM_APPIMAGE_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage"

# --- Font Configuration ---
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/FiraMono.zip"
FONT_NAME="FiraMono"
FONT_INSTALL_DIR="${HOME}/.local/share/fonts"

# Set these directly to skip prompts, or leave empty to be prompted.
SSH_TARGET_USER="" # e.g., "your_server_username"
SSH_PUBLIC_KEY=""  # e.g., "ssh-rsa AAAA...your-public-key-string...user@host"

# --- Required APT Packages ---
# These packages will be installed.
REQUIRED_APT_PACKAGES=(
    curl git unzip fontconfig stow fzf pipx
    zsh-syntax-highlighting zsh-autosuggestions command-not-found
    ripgrep
)

CORE_PACKAGES_TO_STOW=(
    "zsh"
    "tmux"
    "git"
    "zsh_plugins"
    "dockerfiles"
)

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

set -eo pipefail # Exit on error and on pipe failures

script_exit_handler() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo -e "\n${ERROR} Script exited prematurely with status ${exit_code}."
    fi
}
trap script_exit_handler EXIT

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
    sudo apt-get update -q
    sudo apt-get install -q "${REQUIRED_APT_PACKAGES[@]}"
    if [ $? -ne 0 ]; then
        echo -e "${ERROR} Failed to install some required packages with apt-get. Please check the output above."
        return 1
    fi
}

install_nerd_font() {
    echo -e "${STEP} Installing ${FONT_NAME} Nerd Font..."
    if [ -d "${FONT_INSTALL_DIR}/${FONT_NAME}" ]; then
        echo -e "${INFO} ${FONT_NAME} Nerd Font is already installed. Skipping."
        return 0
    fi

    local TEMP_DIR
    TEMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TEMP_DIR"' RETURN # Cleanup on function return

    echo -e "${INFO} Downloading ${FONT_NAME} Nerd Font..."
    if ! curl --fail --location -o "${TEMP_DIR}/font.zip" "${FONT_URL}"; then
        echo -e "${ERROR} Failed to download ${FONT_NAME} Nerd Font. Skipping installation."
        return 1
    fi

    mkdir -p "${FONT_INSTALL_DIR}/${FONT_NAME}"
    if ! unzip -q -o "${TEMP_DIR}/font.zip" -d "${FONT_INSTALL_DIR}/${FONT_NAME}"; then
        echo -e "${ERROR} Failed to extract ${FONT_NAME} Nerd Font. Skipping installation."
        return 1
    fi

    echo -e "${INFO} Updating font cache..."
    fc-cache -fv >/dev/null
    echo -e "${INFO} ${FONT_NAME} Nerd Font installed successfully."
    return 0
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
    return 0
}

setup_argcomplete() {
    echo -e "\n${STEP} Setting up Python Argcomplete..."
    if ! command -v pipx &>/dev/null; then
        echo -e "${ERROR} pipx is not installed. This is required."
        return 1
    fi

    # Use -q for quiet install
    pipx install argcomplete -q
    if activate-global-python-argcomplete &>/dev/null; then
        echo -e "${INFO} Argcomplete activated."
    else
        echo -e "${ERROR} Failed to activate global completions (activate-global-python-argcomplete)."
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
        echo -e "${WARN} Package '${pkg}' not found in dotfiles directory. Skipping."
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

# SSH Hardening Configuration
configure_ssh_hardening() {
    echo -e "${STEP} Configuring SSH hardening..."

    local current_target_user="$SSH_TARGET_USER"
    local current_public_key="$SSH_PUBLIC_KEY"

    # If global variables are empty, prompt the user
    if [ -z "$current_target_user" ]; then
        read -p "$(echo -e ${STEP}) Enter the target username for SSH configuration: " current_target_user
    fi
    if [ -z "$current_public_key" ]; then
        read -p "$(echo -e ${STEP}) Enter the SSH public key (e.g., ssh-rsa AAAA...): " current_public_key
    fi

    if [ -z "$current_target_user" ] || [ -z "$current_public_key" ]; then
        echo -e "${ERROR} Target username or public key cannot be empty. Skipping SSH hardening."
        return 1
    fi

    local SSH_CONFIG_FILE="/etc/ssh/sshd_config"
    # Use || true to prevent 'set -e' from exiting if getent fails (e.g., user doesn't exist)
    local USER_HOME=$(getent passwd "$current_target_user" | cut -d: -f6 || true)
    local SSH_DIR="$USER_HOME/.ssh"
    local AUTH_KEYS_FILE="$SSH_DIR/authorized_keys"

    if [ -z "$USER_HOME" ]; then
        echo -e "${ERROR} User '$current_target_user' does not exist. Skipping SSH hardening."
        return 1
    fi
    echo -e "${INFO} Configuring SSH for user: $current_target_user"

    # Helper function for sshd_config specific to this scope, using sudo
    set_sshd_config_sudo() {
        local key="$1"
        local value="$2"
        echo -e "${INFO} Ensuring $key is set to $value..."
        if sudo grep -qE "^\s*#*\s*$key\s+" "$SSH_CONFIG_FILE"; then
            sudo sed -i -E "s/^\s*#*\s*$key\s+.*/$key $value/" "$SSH_CONFIG_FILE"
        else
            echo "$key $value" | sudo tee -a "$SSH_CONFIG_FILE" > /dev/null
        fi
        if [ $? -ne 0 ]; then
             echo -e "${ERROR} Failed to set $key in $SSH_CONFIG_FILE."
             return 1
        fi
    }

    echo -e "${INFO} Hardening $SSH_CONFIG_FILE..."
    set_sshd_config_sudo "PubkeyAuthentication" "yes" || return 1
    set_sshd_config_sudo "PasswordAuthentication" "no" || return 1
    set_sshd_config_sudo "PermitRootLogin" "no" || return 1
    set_sshd_config_sudo "ChallengeResponseAuthentication" "no" || return 1
    # set_sshd_config_sudo "UsePAM" "no" # Use with extreme caution!
    echo -e "${INFO} sshd_config modifications completed."

    echo -e "${INFO} Adding public key to $AUTH_KEYS_FILE..."
    sudo mkdir -p "$SSH_DIR" || { echo -e "${ERROR} Failed to create $SSH_DIR."; return 1; }
    sudo touch "$AUTH_KEYS_FILE" || { echo -e "${ERROR} Failed to touch $AUTH_KEYS_FILE."; return 1; }\

    if ! sudo grep -q -F "$current_public_key" "$AUTH_KEYS_FILE"; then
        echo "$current_public_key" | sudo tee -a "$AUTH_KEYS_FILE" > /dev/null || { echo -e "${ERROR} Failed to add public key."; return 1; }
        echo -e "${INFO} Public key added."
    else
        echo -e "${INFO} Public key already exists."
    fi

    echo -e "${INFO} Setting correct permissions..."
    sudo chown -R "$current_target_user:$current_target_user" "$SSH_DIR" || { echo -e "${ERROR} Failed to chown $SSH_DIR."; return 1; }
    sudo chmod 700 "$SSH_DIR" || { echo -e "${ERROR} Failed to chmod 700 $SSH_DIR."; return 1; }
    sudo chmod 600 "$AUTH_KEYS_FILE" || { echo -e "${ERROR} Failed to chmod 600 $AUTH_KEYS_FILE."; return 1; }
    echo -e "${INFO} Permissions set."

    echo -e "${INFO} Validating sshd_config..."
    if sudo sshd -t &> /dev/null; then # Redirect stderr to /dev/null to avoid verbose output
        echo -e "${INFO} sshd_config syntax is OK."
        echo -e "${INFO} Restarting sshd service to apply changes..."
        if sudo systemctl restart sshd; then
            echo -e "${INFO} SSH configuration applied successfully."
        else
            echo -e "${ERROR} Failed to restart sshd service. Please check manually."
            return 1
        fi
    else
        echo -e "${ERROR} sshd_config syntax check failed! Changes have NOT been applied."
        echo -e "${ERROR} Review $SSH_CONFIG_FILE for errors. It might be in a bad state."
        return 1
    fi
    return 0
}

# --- Main Script Execution ---
main() {
    install_required_packages

    if ask_to_proceed "Do you want to install Neovim and its configuration?"; then
        install_neovim
        stow_package "nvim"
        local nvim_installed=true
    else
        local nvim_installed=false
    fi

    if ask_to_proceed "Do you want to install FiraMono Nerd Font?"; then
        install_nerd_font
        local font_installed=true
    else
        local font_installed=false
    fi

    if ask_to_proceed "Do you want to configure SSH hardening (Pubkey auth, no password)?"; then
        configure_ssh_hardening
    fi

    # Stow all the core, unconditional packages (excluding nvim now)
    echo -e "${STEP} Stowing core dotfiles..."
    for pkg in "${CORE_PACKAGES_TO_STOW[@]}"; do
        stow_package "$pkg"
    done

    # Setup argcomplete after dotfiles are stowed, as zsh dotfiles add ~/.local/bin to PATH
    # setup_argcomplete

    echo -e "${GREEN}--- Setup Complete ---${NC}"
    echo -e "${YELLOW}Next Steps:${NC}"
    if [ "$font_installed" = true ]; then
        echo -e "1. ${YELLOW}IMPORTANT:${NC} Open your terminal's settings and change its font to 'FiraMono Nerd Font'."
    else
        echo -e "1. Open your terminal's settings to your preferred font."
    fi
    echo -e "2. Restart your terminal to apply all changes."
    if [ "$nvim_installed" = true ]; then
        echo -e "3. Run \`${BLUE}nvim${NC}\` and then run \`:PackerSync\` to install the plugins."
    fi
}

main
