#!/bin/bash

# bootstrap.sh: Clones the dotfiles repository and executes the setup script with the 'pwn' and 'ssh' profiles.

DOTFILES_REPO="https://github.com/mm4rks/dotfiles.git" # Assuming this is the correct repo URL
DOTFILES_DIR="$HOME/.dotfiles"

echo "[*] Starting pwnbox bootstrap process..."

# Clone the dotfiles repository
if [ -d "$DOTFILES_DIR" ]; then
    echo "[!] Dotfiles directory already exists. Pulling latest changes..."
    git -C "$DOTFILES_DIR" pull
else
    echo "[*] Cloning dotfiles repository from $DOTFILES_REPO to $DOTFILES_DIR..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    if [ $? -ne 0 ]; then
        echo "[-] Error: Failed to clone dotfiles repository."
        exit 1
    fi
fi

# Execute the setup scripts with the 'pwn' and 'ssh' profiles
# The system_setup.sh script needs to be run with sudo
if [ -f "$DOTFILES_DIR/system_setup.sh" ]; then
    echo "[*] Executing system_setup.sh with 'pwn' and 'ssh' profiles..."
    chmod +x "$DOTFILES_DIR/system_setup.sh"
    sudo "$DOTFILES_DIR/system_setup.sh" pwn ssh
    if [ $? -ne 0 ]; then
        echo "[-] Error: system_setup.sh failed."
        exit 1
    fi
else
    echo "[-] Error: system_setup.sh not found in $DOTFILES_DIR."
    exit 1
fi

echo "[*] Pwnbox bootstrap complete."
