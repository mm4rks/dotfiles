#!/bin/bash
#
# setup.sh: Automated, profile-based development environment setup.
# This script is designed to be idempotent and non-interactive, supporting
# Debian, Arch, and derivative distributions (e.g., Kali, Parrot).
#

set -eo pipefail # Exit on error and on pipe failures

# --- Configuration & Defaults ---
DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# --- Font Configuration ---
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraMono.zip"
FONT_NAME="FiraMono"
FONT_INSTALL_DIR="${HOME}/.local/share/fonts"

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

log_info() { echo -e "${INFO} $1"; }
log_warn() { echo -e "${WARN} $1"; }
log_error() { echo -e "${ERROR} $1"; }
log_step() { echo -e "${STEP} $1"; }

script_exit_handler() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "Script exited prematurely with status ${exit_code}."
    fi
}
trap script_exit_handler EXIT

# --- System Detection ---
OS_ID=""
OS_ID_LIKE=""
determine_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID=$ID
        OS_ID_LIKE=$ID_LIKE
    else
        log_error "Cannot determine OS distribution."
        exit 1
    fi
    log_info "Detected OS: $OS_ID"
}

# --- Usage Message ---
usage() {
    cat <<EOF
Usage: $0 [profile...] [options...]

Automated, profile-based development environment setup.
The 'default' profile is always installed.

Profiles:
  dev         Installs developer tools (Docker, Node.js, Gemini CLI).
  rev         Installs reverse engineering tools (Ghidra, Joern, Semgrep).
  pwn         Installs pentesting tools (NetExec) and hardens SSH.
  all         Installs all profiles.

Options:
  --ssh-key "..."  Specify the public SSH key for SSH configuration (used with 'pwn' or 'all').
  -h, --help       Display this help message.

EOF
    exit 0
}

# --- Installation Helpers ---

install_packages() {
    local packages=($@)
    if [ ${#packages[@]} -eq 0 ]; then
        return
    fi
    
    log_step "Installing system packages: ${packages[*]}..."
    case "$OS_ID" in
        arch)
            sudo pacman -Syu --noconfirm --needed "${packages[@]}"
            ;;
        ubuntu|debian|kali|parrot)
            sudo DEBIAN_FRONTEND=noninteractive apt-get update -q
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -q -y "${packages[@]}"
            ;;
        *)
            log_error "Unsupported OS for package installation: $OS_ID"
            exit 1
            ;;
    esac
}

install_pipx_package() {
    local package_name=$1
    local install_spec=$2
    if command -v "$package_name" &>/dev/null; then
        log_info "${package_name} is already installed. Skipping."
        return 0
    fi
    log_info "Installing ${package_name} with pipx..."
    if ! pipx install "$install_spec"; then
        log_warn "Failed to install ${package_name} with pipx."
    else
        log_info "${package_name} installed successfully."
    fi
}

uninstall_conflicting_packages() {
    if [ "$OS_ID" = "parrot" ]; then
        log_info "On Parrot OS, ensuring apt versions of nvim and fzf are removed..."
        if dpkg -s "neovim" &>/dev/null; then
            log_info "Removing existing 'neovim' package from apt to install latest from GitHub."
            sudo apt-get remove -q -y --purge neovim neovim-common
            sudo apt-get autoremove -q -y
        fi

        if dpkg -s "fzf" &>/dev/null; then
            log_info "Removing existing 'fzf' package from apt to install latest from GitHub."
            sudo apt-get remove -q -y --purge fzf
        fi
    fi
}

# --- Component Installation Functions ---

install_core_tools() {
    log_step "Installing core tools and dependencies..."
    
    local apt_packages=(
        curl git stow jq make cmake unzip fontconfig xclip tree
        python3 python3-pip python3-venv pipx zsh tmux ripgrep
        bat fd-find wl-clipboard fuse3
    )
    local arch_packages=(
        curl git stow jq make cmake unzip fontconfig xclip tree
        python python-pip python-pipx zsh tmux ripgrep bat fd
        eza git-delta choose wl-clipboard
    )

    case "$OS_ID" in
        arch)
            install_packages "${arch_packages[@]}"
            ;;
        *)
            install_packages "${apt_packages[@]}"
            # Fallback for tools not in default Debian/Ubuntu repos
            if ! command -v eza &>/dev/null; then install_eza_from_github; fi
            if ! command -v choose &>/dev/null; then install_choose_with_cargo; fi
            if ! command -v delta &>/dev/null; then install_delta_from_github; fi
            ;;
    esac

    pipx ensurepath
    install_pipx_package "tldr" "tldr"
    install_fzf_from_github
}

create_compatibility_symlinks() {
    log_step "Creating compatibility symlinks..."
    mkdir -p "$HOME/.local/bin"
    
    # Symlink for fdfind -> fd
    if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
        if [ ! -L "$HOME/.local/bin/fd" ]; then
            ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
            log_info "Symlinked fdfind to fd"
        fi
    fi
    
    # Symlink for batcat -> bat
    if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
        if [ ! -L "$HOME/.local/bin/bat" ]; then
            ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
            log_info "Symlinked batcat to bat"
        fi
    fi
}

install_eza_from_github() {
    if command -v eza &>/dev/null; then
        log_info "eza is already installed. Skipping."
        return 0
    fi
    log_info "Installing eza from GitHub..."
    local TEMP_DIR
    TEMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TEMP_DIR"' RETURN

    local EZA_URL
    EZA_URL=$(curl -s https://api.github.com/repos/eza-community/eza/releases/latest | jq -r '.assets[] | select(.name | endswith("x86_64-unknown-linux-gnu.tar.gz")) | .browser_download_url' | head -n 1)
    if [ -z "$EZA_URL" ]; then
        log_warn "Could not find eza release URL. Skipping."
        return 1
    fi
    
    curl --fail --location -o "${TEMP_DIR}/eza.tar.gz" "$EZA_URL"
    tar -xzf "${TEMP_DIR}/eza.tar.gz" -C "${TEMP_DIR}"
    sudo mv "${TEMP_DIR}/eza" /usr/local/bin/
    log_info "eza installed."
}

install_delta_from_github() {
    if command -v delta &>/dev/null; then
        log_info "git-delta is already installed. Skipping."
        return 0
    fi
    log_info "Installing git-delta from GitHub..."
    local TEMP_DIR
    TEMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TEMP_DIR"' RETURN

    local DELTA_URL
    DELTA_URL=$(curl -s https://api.github.com/repos/dandavison/delta/releases/latest | jq -r '.assets[] | select(.name | test("delta-.*-x86_64-unknown-linux-gnu.tar.gz$")) | .browser_download_url' | head -n 1)
    if [ -z "$DELTA_URL" ]; then
        log_warn "Could not find git-delta release URL. Skipping."
        return 1
    fi

    curl --fail --location -o "${TEMP_DIR}/delta.tar.gz" "$DELTA_URL"
    # The tarball contains a directory, so strip it
    tar -xzf "${TEMP_DIR}/delta.tar.gz" -C "${TEMP_DIR}" --strip-components=1
    
    sudo mv "${TEMP_DIR}/delta" /usr/local/bin/
    log_info "git-delta installed successfully."
}


install_choose_with_cargo() {
    if command -v choose &>/dev/null; then
        log_info "choose is already installed. Skipping."
        return 0
    fi
    log_info "Installing 'choose' with cargo..."
    if ! command -v cargo &>/dev/null; then
        log_info "cargo not found. Installing Rust..."
        if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
            log_error "Failed to install Rust."
            return 1
        fi
        source "$HOME/.cargo/env"
    fi
    cargo install choose
}

install_fzf_from_github() {
    if command -v fzf &>/dev/null; then
        log_info "fzf is already installed. Skipping."
        return 0
    fi
    log_info "Installing fzf from GitHub..."
    if ! git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf; then
        log_error "Failed to clone fzf repository."
        return 1
    fi
    # The --all flag installs for all users, creates a backup of existing files,
    # and sets up key bindings and fuzzy completion
    if ! ~/.fzf/install --all; then
        log_error "Failed to install fzf."
        return 1
    fi
    log_info "fzf installed successfully."
}


install_nerd_font() {
    if fc-list | grep -q "$FONT_NAME"; then
        log_info "${FONT_NAME} Nerd Font is already installed. Skipping."
        return 0
    fi
    log_info "Installing ${FONT_NAME} Nerd Font..."
    local TEMP_DIR
    TEMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TEMP_DIR"' RETURN

    curl --fail --location -o "${TEMP_DIR}/font.zip" "${FONT_URL}"
    mkdir -p "${FONT_INSTALL_DIR}/${FONT_NAME}"
    unzip -q -o "${TEMP_DIR}/font.zip" -d "${FONT_INSTALL_DIR}/${FONT_NAME}"
    fc-cache -fv >/dev/null
    log_info "${FONT_NAME} Nerd Font installed."
}

install_neovim() {
    if command -v nvim &>/dev/null; then
        log_info "Neovim is already installed. Skipping."
        return 0
    fi
    log_info "Installing Neovim AppImage..."
    local NVIM_URL
    NVIM_URL=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest | jq -r '.assets[] | select(.name == "nvim-linux-x86_64.appimage") | .browser_download_url')
    
    if [ -z "$NVIM_URL" ] || [ "$NVIM_URL" == "null" ]; then
        log_error "Could not determine Neovim download URL."
        return 1
    fi
    
    mkdir -p "$NVIM_INSTALL_DIR"
    curl --fail --location -o "$NVIM_APPIMAGE_PATH" "$NVIM_URL"
    chmod u+x "$NVIM_APPIMAGE_PATH"
    log_info "Neovim installed to ${NVIM_APPIMAGE_PATH}"
}

change_shell_to_zsh() {
    local user="${SUDO_USER:-$(whoami)}"
    local zsh_path
    zsh_path=$(which zsh)
    if [ -z "$zsh_path" ]; then
        log_warn "zsh not found. Cannot change shell."
        return 1
    fi
    if ! grep -Fxq "$zsh_path" /etc/shells; then
        log_info "Adding $zsh_path to /etc/shells"
        echo "$zsh_path" | sudo tee -a /etc/shells
    fi
    if [ "$(getent passwd "$user" | cut -d: -f7)" != "$zsh_path" ]; then
        log_step "Changing default shell to zsh for $user..."
        if sudo chsh -s "$zsh_path" "$user"; then
            log_info "Default shell changed to zsh. Please log out and log back in for the change to take effect."
        else
            log_error "Failed to change default shell."
        fi
    else
        log_info "Default shell is already zsh."
    fi
}

stow_dotfiles() {
    local packages_to_stow=($@)
    log_step "Stowing dotfiles: ${packages_to_stow[*]}..."

    if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
        log_info "Backing up existing .zshrc to .zshrc.bak..."
        mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
    fi

    for pkg in "${packages_to_stow[@]}"; do
        if [ ! -d "${DOTFILES_DIR}/${pkg}" ]; then
            log_warn "Dotfile package '${pkg}' not found. Skipping."
            continue
        fi
        log_info "Stowing '${pkg}'..."
        stow --dir="$DOTFILES_DIR" --target="$HOME" --restow "$pkg" 2>/dev/null || log_warn "Stow found conflicts for '${pkg}'. It might be partially stowed."
    done
}

install_docker() {
    local current_user="${SUDO_USER:-$(whoami)}"
    if command -v docker &>/dev/null; then
        log_info "Docker is already installed. Ensuring service is running and permissions are set."
    else
        log_step "Installing Docker..."
        local docker_script
        docker_script=$(curl -fsSL https://get.docker.com)
        
        if [ "$OS_ID" = "kali" ]; then
            log_info "Applying Kali-specific patch to Docker install script."
            docker_script=$(echo "$docker_script" | sed 's/kali-rolling/bookworm/g')
        fi

        echo "$docker_script" | sudo sh
        log_info "Docker installed."
    fi
    
    log_step "Starting Docker service and configuring permissions..."
    
    # Enable and start Docker service
    if ! sudo systemctl is-active --quiet docker; then
        log_info "Starting and enabling Docker service..."
        sudo systemctl enable --now docker
    fi

    # Create docker group if it doesn't exist
    if ! getent group docker > /dev/null; then
        log_info "Creating docker group..."
        sudo groupadd docker
    fi

    # Add current user to docker group
    if groups "$current_user" | grep -q -w "docker"; then
        log_info "User '$current_user' is already in the 'docker' group."
    else
        log_info "Adding user '$current_user' to the 'docker' group..."
        sudo usermod -aG docker "$current_user"
        log_warn "You must log out and log back in for group changes to take effect."
    fi
}

ensure_nodejs() {
    if command -v node &>/dev/null && [[ $(node -v | cut -d'v' -f2 | cut -d'.' -f1) -ge 18 ]]; then
        return 0
    fi
    log_info "Installing Node.js v20 LTS..."
    install_packages "ca-certificates" "curl" "gnupg"
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
    install_packages "nodejs"
    log_info "Node.js installed."
}

install_npm_global() {
    local package=$1
    if npm list -g | grep -q "$package"; then
        log_info "NPM package ${package} is already installed. Skipping."
        return 0
    fi
    log_info "Installing global NPM package: ${package}"
    sudo npm install -g "$package"
}

install_jdk() {
    if command -v java &>/dev/null && java -version 2>&1 | grep -q "version \"21"; then
        log_info "JDK 21 is already installed. Skipping."
        return 0
    fi
    log_step "Installing JDK 21..."
    install_packages "openjdk-21-jdk"
    log_info "JDK 21 installed successfully."
}

install_joern() {
    if command -v joern &>/dev/null; then
        log_info "Joern is already installed. Skipping."
        return 0
    fi
    install_jdk
    log_step "Installing Joern..."
    local TEMP_DIR
    TEMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TEMP_DIR"' RETURN
    curl -L "https://github.com/joernio/joern/releases/latest/download/joern-install.sh" -o "${TEMP_DIR}/joern-install.sh"
    chmod +x "${TEMP_DIR}/joern-install.sh"
    sudo "${TEMP_DIR}/joern-install.sh" --non-interactive
    log_info "Joern installed successfully."
}

install_ghidra() {
    if command -v ghidra &>/dev/null; then
        log_info "Ghidra is already installed. Skipping."
        return 0
    fi
    install_jdk
    log_step "Installing Ghidra..."
    local TEMP_DIR
    TEMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TEMP_DIR"' RETURN

    local GHIDRA_URL
    GHIDRA_URL=$(curl -s https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/latest | jq -r '.assets[] | select(.name | endswith(".zip")) | .browser_download_url')
    if [ -z "$GHIDRA_URL" ]; then
        log_warn "Could not find Ghidra release URL. Skipping."
        return 1
    fi

    curl --fail --location -o "${TEMP_DIR}/ghidra.zip" "$GHIDRA_URL"
    local GHIDRA_DIR_NAME
    GHIDRA_DIR_NAME=$(unzip -Z -1 "${TEMP_DIR}/ghidra.zip" | head -1 | sed 's/\\\///')
    unzip -q -o "${TEMP_DIR}/ghidra.zip" -d "${TEMP_DIR}"
    
    sudo mv "${TEMP_DIR}/${GHIDRA_DIR_NAME}" /opt/ghidra
    sudo ln -sf /opt/ghidra/ghidraRun /usr/local/bin/ghidra
    log_info "Ghidra installed successfully."
}

install_bloodhound() {
    if command -v bloodhound-cli &>/dev/null; then
        log_info "bloodhound-cli is already installed. Skipping."
        return 0
    fi
    
    log_step "Installing BloodHound..."
    
    # Dependency: Docker
    install_docker

    local TEMP_DIR
    TEMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TEMP_DIR"' RETURN

    local BLOODHOUND_CLI_URL="https://github.com/SpecterOps/bloodhound-cli/releases/latest/download/bloodhound-cli-linux-amd64.tar.gz"
    
    log_info "Downloading bloodhound-cli from ${BLOODHOUND_CLI_URL}..."
    if ! curl --fail --location -o "${TEMP_DIR}/bloodhound-cli.tar.gz" "$BLOODHOUND_CLI_URL"; then
        log_error "Failed to download bloodhound-cli."
        return 1
    fi
    
    tar -xzf "${TEMP_DIR}/bloodhound-cli.tar.gz" -C "${TEMP_DIR}"
    sudo mv "${TEMP_DIR}/bloodhound-cli" /usr/local/bin/
    log_info "bloodhound-cli installed to /usr/local/bin/."
    log_warn "To complete BloodHound setup, run 'bloodhound-cli install'. This will download and start the necessary Docker containers."
}

configure_ssh_hardening() {
    local public_key="$1"
    if [ -z "$public_key" ]; then
        log_error "No SSH public key provided for hardening. Skipping."
        return 1
    fi
    log_step "Configuring and hardening SSH server..."
    install_packages "openssh-server"
    
    local SSH_CONFIG_FILE="/etc/ssh/sshd_config"
    local SSH_DIR="$HOME/.ssh"
    local AUTH_KEYS_FILE="$SSH_DIR/authorized_keys"

    mkdir -p "$SSH_DIR"
    touch "$AUTH_KEYS_FILE"

    if ! grep -q -F "$public_key" "$AUTH_KEYS_FILE"; then
        echo "$public_key" >> "$AUTH_KEYS_FILE"
        log_info "Public key added to authorized_keys."
    else
        log_info "Public key already exists in authorized_keys."
    fi
    
    chown -R "$USER:$USER" "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    chmod 600 "$AUTH_KEYS_FILE"

    set_sshd_config() {
        sudo sed -i -E "s/^	*#?\s*$1\s+.*/$1 $2/" "$SSH_CONFIG_FILE"
    }

    log_info "Applying sshd_config hardening settings..."
    set_sshd_config "PubkeyAuthentication" "yes"
    set_sshd_config "PasswordAuthentication" "no"
    set_sshd_config "PermitRootLogin" "no"
    set_sshd_config "ChallengeResponseAuthentication" "no"

    if sudo sshd -t; then
        log_info "sshd config is valid. Restarting service."
        sudo systemctl restart ssh || sudo systemctl restart sshd
    else
        log_error "sshd_config syntax check failed! Check /etc/ssh/sshd_config."
        return 1
    fi
    log_info "SSH hardening complete."
}


# --- Main Logic ---
main() {
    if ! sudo -n true 2>/dev/null; then
        log_error "This script requires sudo privileges. Please run it with a user that has sudo access."
        exit 1
    fi
    
    determine_os
    uninstall_conflicting_packages

    local PROFILE_DEV=false
    local PROFILE_REV=false
    local PROFILE_PWN=false
    local SSH_PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKcqyUBUO957MzQiG8Mx0RovRLy3b/rqtNk+heyHN083 mm4rks@posteo.de"

    while [ $# -gt 0 ]; do
        case "$1" in
            dev) PROFILE_DEV=true; shift ;;
            rev) PROFILE_REV=true; shift ;;
            pwn) PROFILE_PWN=true; shift ;;
            all) 
                PROFILE_DEV=true
                PROFILE_REV=true
                PROFILE_PWN=true
                shift
                ;;
            --ssh-key) 
                SSH_PUBLIC_KEY="$2"
                shift 2
                ;;
            -h|--help) usage ;; 
            *) 
                # Silently ignore 'default' profile argument
                if [ "$1" != "default" ]; then
                    log_error "Unknown option: $1"
                    usage
                fi
                shift
                ;;
        esac
    done

    # --- Profile Execution ---
    
    log_step "--- Installing 'default' profile ---"
    install_core_tools
    create_compatibility_symlinks
    install_nerd_font
    install_neovim
    
    local core_stow_packages=("zsh" "tmux" "eza" "git" "vivid" "nvim")
    local arch_stow_packages=("alacritty" "hypr" "kanshi" "waybar")
    
    local packages_to_stow=("${core_stow_packages[@]}")
    if [ "$OS_ID" = "arch" ]; then
        packages_to_stow+=("${arch_stow_packages[@]}")
    fi
    stow_dotfiles "${packages_to_stow[@]}"
    change_shell_to_zsh
    
    if [ "$PROFILE_DEV" = true ]; then
        log_step "--- Installing 'dev' profile ---"
        install_docker
        if [ "$OS_ID" != "arch" ]; then
            ensure_nodejs
            install_npm_global "@google/gemini-cli@nightly"
            install_npm_global "pure-prompt"
        else
            install_packages "npm" "nodejs"
            install_npm_global "@google/gemini-cli@nightly"
            install_npm_global "pure-prompt"
        fi
    fi

    if [ "$PROFILE_REV" = true ]; then
        log_step "--- Installing 'rev' profile ---"
        install_joern
        install_ghidra
        install_pipx_package "semgrep" "semgrep"
        install_pipx_package "flare-floss" "flare-floss"
    fi
    
    if [ "$PROFILE_PWN" = true ]; then
        log_step "--- Installing 'pwn' profile ---"
        install_pipx_package "netexec" "git+https://github.com/Pennyw0rth/NetExec"
        install_pipx_package "certipy" "certipy-ad"
        install_pipx_package "bloodhound-ce" "bloodhound-ce"
        install_bloodhound
        configure_ssh_hardening "$SSH_PUBLIC_KEY"
    fi
    
    log_info "--- Setup Complete ---"
    log_warn "Please restart your terminal or log out/in for all changes to take effect."
}

main "$@"
