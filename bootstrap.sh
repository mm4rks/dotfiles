#!/bin/bash
set -euo pipefail

# bootstrap.sh: Clones the dotfiles repository and executes the setup script with the 'pwn' and 'ssh' profiles.

DOTFILES_REPO="https://github.com/mm4rks/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

main() {
    echo "[*] Starting pwnbox bootstrap process..."

    # Clone or update the dotfiles repository
    if [ -d "$DOTFILES_DIR" ]; then
        echo "[!] Dotfiles directory already exists. Pulling latest changes..."
        git -C "$DOTFILES_DIR" pull
    else
        echo "[*] Cloning dotfiles repository from $DOTFILES_REPO to $DOTFILES_DIR..."
        if ! git clone "$DOTFILES_REPO" "$DOTFILES_DIR"; then
            echo "[-] Error: Failed to clone dotfiles repository."
            exit 1
        fi
    fi

    # Execute the setup script with the 'pwn' and 'ssh' profiles
    if [ -f "$DOTFILES_DIR/setup.sh" ]; then
        echo "[*] Executing setup.sh with 'pwn' and 'ssh' profiles..."
        chmod +x "$DOTFILES_DIR/setup.sh"
        if ! "$DOTFILES_DIR/setup.sh" pwn ssh; then
            echo "[-] Error: setup.sh failed."
            exit 1
        fi
    else
        echo "[-] Error: setup.sh not found in $DOTFILES_DIR."
        exit 1
    fi

    echo "[*] Pwnbox bootstrap complete."
}

main "$@"
