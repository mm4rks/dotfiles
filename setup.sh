#!/bin/bash
DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)


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
    curl git unzip fontconfig stow jq
    zsh-syntax-highlighting zsh-autosuggestions command-not-found
    ripgrep tmux python3 python3-pip python3-venv tree xclip bat
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
    if ! sudo apt-get install -q -y "${REQUIRED_APT_PACKAGES[@]}"; then
        echo -e "${ERROR} Failed to install some required packages with apt-get. Please check the output above."
        exit 1
    fi
}

install_docker() {
    if command -v docker &>/dev/null; then
        echo -e "${INFO} Docker is already installed. Skipping."
        return 0
    fi

    if ! ask_to_proceed "Do you want to install Docker?"; then
        echo -e "${INFO} Skipping Docker installation."
        return 0
    fi

    echo -e "\n${STEP} Installing Docker using the official convenience script..."
    echo -e "${INFO} Ensuring Zsh vendor completions directory exists..."
    sudo mkdir -p /usr/share/zsh/vendor-completions
    if ! curl -fsSL https://get.docker.com -o get-docker.sh; then
        echo -e "${ERROR} Failed to download Docker installation script."
        return 1
    fi

    if ! sudo sh get-docker.sh; then
        echo -e "${ERROR} Failed to execute Docker installation script."
        rm get-docker.sh
        return 1
    fi
    rm get-docker.sh

    echo -e "${INFO} Adding current user to the docker group..."
    if ! sudo usermod -aG docker "$USER"; then
        echo -e "${WARN} Failed to add user '$USER' to the 'docker' group. You may need to do this manually and restart your session."
        return 1
    fi

    echo -e "${INFO} Docker installed and user added to 'docker' group. Please log out and log back in for group changes to take effect."
    return 0
}

install_fzf_from_github() {
    if command -v fzf &>/dev/null; then
        echo -e "${INFO} fzf is already installed. Skipping."
        return 0
    fi

    echo -e "\n${STEP} Installing fzf from GitHub..."
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

ensure_nodejs_installed() {
    # Check for a modern version of Node.js (v18+), and install it from NodeSource if needed.
    if ! command -v node &>/dev/null || [[ $(node -v | cut -d'v' -f2 | cut -d'.' -f1) -lt 18 ]]; then
        echo -e "${INFO} A modern version of Node.js (v18+) is required. Installing Node.js v20 LTS..."
        
        # Add NodeSource repository
        sudo apt-get update -q
        sudo apt-get install -y ca-certificates curl gnupg
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
        
        NODE_MAJOR=20
        echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
        
        # Install Node.js
        sudo apt-get update -q
        if ! sudo apt-get install -q -y nodejs; then
            echo -e "${ERROR} Failed to install Node.js from NodeSource. Aborting npm package installation."
            return 1
        fi
        echo -e "${INFO} Node.js installed successfully."
    fi
    return 0
}

install_npm_packages() {
    local npm_packages=()
    
    if ask_to_proceed "Do you want to install the Gemini CLI (@google/gemini-cli)?"; then
        npm_packages+=("@google/gemini-cli@nightly")
    fi

    if ! command -v tldr &>/dev/null && ! command -v devdocs-cli &>/dev/null; then
        if ask_to_proceed "Do you want to install additional CLI tools (tldr, devdocs-cli)?"; then
            npm_packages+=("tldr" "devdocs-cli")
        fi
    fi

    if [ ${#npm_packages[@]} -eq 0 ]; then
        echo -e "${INFO} No npm packages selected for installation. Skipping."
        return 0
    fi

    ensure_nodejs_installed || return 1

    echo -e "\n${STEP} Installing selected npm packages: ${npm_packages[*]}..."
    if ! sudo npm install -g "${npm_packages[@]}"; then
        echo -e "${ERROR} Failed to install one or more npm packages."
        return 1
    fi

    echo -e "${INFO} npm packages installed successfully."
    return 0
}

install_nerd_font() {
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

stow_package() {
    local pkg="$1"
    local stow_output

    if [ -z "$pkg" ]; then
        echo -e "${WARN} stow_package called with empty package name. Skipping."
        return 1
    fi

    local source_dir="${DOTFILES_DIR}/${pkg}"
    if [ ! -d "$source_dir" ]; then
        echo -e "${WARN} Package '${pkg}' not found in dotfiles directory. Skipping."
        return 1
    fi

    echo -e "${INFO} Stowing '${pkg}'..."
    if ! stow_output=$(stow --dir="$DOTFILES_DIR" --target="$HOME" --restow "$pkg" 2>&1); then
        echo -e "${WARN} Failed to stow '${pkg}'. Please resolve conflicts manually."
        echo -e "${YELLOW}Stow output:${NC}\n$stow_output"
    fi
}

# SSH Hardening Configuration
configure_ssh_hardening() {
    sudo apt install openssh-server -q -y

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

    # Helper function for sshd_config specific to this scope, using sudo
    set_sshd_config_sudo() {
        local key="$1"
        local value="$2"
        echo -e "${INFO} $key $value"
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

    echo -e "${INFO} write sshd_config modifications to $SSH_CONFIG_FILE."
    set_sshd_config_sudo "PubkeyAuthentication" "yes" || return 1
    set_sshd_config_sudo "PasswordAuthentication" "no" || return 1
    set_sshd_config_sudo "PermitRootLogin" "no" || return 1
    set_sshd_config_sudo "ChallengeResponseAuthentication" "no" || return 1
    # set_sshd_config_sudo "UsePAM" "no" # Use with extreme caution!

    # Create the privilege separation directory if it doesn't exist
    if [ ! -d /run/sshd ]; then
        echo -e "${INFO} Creating /run/sshd directory..."
        sudo mkdir -p /run/sshd
        sudo chmod 755 /run/sshd
    fi

    echo -e "${INFO} Generating SSH host keys..."
    sudo ssh-keygen -A
    echo -e "${INFO} Validating sshd_config..."
    if sudo sshd -t &> /dev/null; then # Redirect stderr to /dev/null to avoid verbose output
        echo -e "${INFO} sshd_config syntax is OK."
        echo -e "${INFO} Restarting sshd service to apply changes..."
        if sudo systemctl restart ssh; then
            echo -e "${INFO} SSH configuration applied successfully."
        else
            echo -e "${ERROR} Failed to restart sshd service. Please check manually."
            return 1
        fi
    else
        echo -e "${ERROR} sshd_config syntax check failed!"
        echo -e "${ERROR} Review $SSH_CONFIG_FILE for errors. It might be in a bad state."
        return 1
    fi
    return 0
}

install_jdk() {
    echo -e "\n${STEP} Checking for JDK 21..."
    if java -version 2>&1 | grep -q "version \"21"; then
        echo -e "${INFO} JDK 21 is already installed. Skipping."
        return 0
    fi

    echo -e "${INFO} JDK 21 not found. Installing openjdk-21-jdk..."
    if ! sudo apt-get install -y openjdk-21-jdk; then
        echo -e "${ERROR} Failed to install JDK 21."
        return 1
    fi
    echo -e "${INFO} JDK 21 installed successfully."
}

install_pipx_packages() {
    if ! command -v pipx &>/dev/null; then
        echo -e "\n${STEP} Installing pipx..."
        if ! sudo apt-get install -y pipx; then
            echo -e "${ERROR} Failed to install pipx."
            return 1
        fi
        pipx ensurepath
        echo -e "${INFO} pipx installed successfully."
    fi

    echo -e "\n${STEP} Installing pipx packages..."
    if ! pipx install semgrep; then
        echo -e "${WARN} Failed to install semgrep."
    fi
}

install_joern() {
    if command -v joern &>/dev/null; then
        echo -e "${INFO} Joern is already installed. Skipping."
        return 0
    fi

    if ! ask_to_proceed "Do you want to install Joern?"; then
        echo -e "${INFO} Skipping Joern installation."
        return 0
    fi

    install_jdk

    echo -e "\n${STEP} Installing Joern..."
    local TEMP_DIR
    TEMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TEMP_DIR"' RETURN

    if ! curl -L "https://github.com/joernio/joern/releases/latest/download/joern-install.sh" -o "${TEMP_DIR}/joern-install.sh"; then
        echo -e "${ERROR} Failed to download Joern installation script."
        return 1
    fi

    chmod +x "${TEMP_DIR}/joern-install.sh"
    if ! sudo "${TEMP_DIR}/joern-install.sh"; then
        echo -e "${ERROR} Failed to install Joern."
        return 1
    fi

    echo -e "${INFO} Joern installed successfully."
}

install_ghidra() {
    if command -v ghidra &>/dev/null; then
        echo -e "${INFO} Ghidra is already installed. Skipping."
        return 0
    fi

    if ! ask_to_proceed "Do you want to install Ghidra?"; then
        echo -e "${INFO} Skipping Ghidra installation."
        return 0
    fi

    install_jdk

    echo -e "\n${STEP} Installing Ghidra..."
    local TEMP_DIR
    TEMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TEMP_DIR"' RETURN

    local GHIDRA_LATEST_URL
    GHIDRA_LATEST_URL=$(curl -s https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/latest | jq -r '.assets[] | select(.name | endswith(".zip")) | .browser_download_url')

    if [ -z "$GHIDRA_LATEST_URL" ]; then
        echo -e "${WARN} Could not find the latest Ghidra release URL. Skipping installation."
        return 1
    fi

    if ! curl --fail --location -o "${TEMP_DIR}/ghidra.zip" "$GHIDRA_LATEST_URL"; then
        echo -e "${WARN} Failed to download Ghidra. Skipping installation."
        return 1
    fi

    if ! sudo unzip -q -o "${TEMP_DIR}/ghidra.zip" -d /opt/; then
        echo -e "${WARN} Failed to extract Ghidra. Skipping installation."
        return 1
    fi

    local GHIDRA_DIR_NAME
    GHIDRA_DIR_NAME=$(unzip -l "${TEMP_DIR}/ghidra.zip" | head -n 4 | tail -n 1 | awk '{print $4}')
    sudo mv /opt/$GHIDRA_DIR_NAME /opt/ghidra

    if ! sudo ln -s /opt/ghidra/ghidraRun /usr/local/bin/ghidra; then
        echo -e "${WARN} Failed to create symlink for Ghidra. Skipping."
        return 1
    fi


    echo -e "${INFO} Ghidra installed successfully."
}

install_code_analysis_tools() {
    if ask_to_proceed "Do you want to install additional code analysis tools (Semgrep, Joern, Ghidra)?"; then
        install_pipx_packages
        install_joern
        install_ghidra
    fi
}

install_dev_env() {
    install_neovim
    stow_package "nvim"
    install_fzf_from_github
    install_nerd_font
}

setup_argcomplete() {
    if ! pipx install argcomplete; then
        echo -e "${WARN} Failed to install argcomplete."
        return 1
    fi
    if command -v activate-global-python-argcomplete &>/dev/null; then
        echo -e "\n${STEP} Activating global python argcomplete..."
        activate-global-python-argcomplete
    else
        echo -e "${WARN} 'activate-global-python-argcomplete' not found in PATH."
    fi
}

# --- Main Script Execution ---
main() {
    # Check for sudo privileges
    if ! sudo -v; then
        echo -e "${ERROR} This script requires sudo privileges. Please run it with a user that has sudo access."
        exit 1
    fi

    install_required_packages
    install_docker
    install_code_analysis_tools

    if command -v nvim &>/dev/null; then
        echo -e "${INFO} Neovim is already installed. Skipping full development environment installation."
    else
        if ask_to_proceed "Do you want to install the full development environment (Neovim, fzf, fonts, etc.)?"; then
            install_dev_env
        fi
    fi

    install_npm_packages

    if ask_to_proceed "Do you want to setup sshd?"; then
        configure_ssh_hardening
    fi

    # Stow all the core, unconditional packages (excluding nvim now)
    echo -e "${STEP} Stowing core dotfiles..."
    for pkg in "${CORE_PACKAGES_TO_STOW[@]}"; do
        stow_package "$pkg"
    done

    setup_argcomplete
    echo -e "${GREEN}--- Setup Complete ---${NC}"
    echo -e "${YELLOW}Next Steps:${NC}"
    echo -e "1. ${YELLOW}IMPORTANT:${NC} Open your terminal's settings and change its font to your preferred font."
    echo -e "2. Restart your terminal to apply all changes."
    echo -e "3. If you installed the dev environment, run \`${BLUE}nvim${NC}\` and then run \`:PackerSync\` to install the plugins."
}

main
