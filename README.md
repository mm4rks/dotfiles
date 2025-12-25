# Dotfiles

This repository contains a collection of dotfiles and a powerful, automated script to set up a consistent development environment across multiple Debian and Arch-based Linux distributions. The setup is designed to be non-interactive and profile-based, allowing for easy customization.

## Features

-   **Automated & Non-Interactive:** The `setup.sh` script runs without requiring user input, making it ideal for automated provisioning.
-   **Profile-Based Installation:** Install only what you need. The setup is modularized into profiles:
    -   `default`: Core tools, Zsh, Tmux, and Neovim. (Always installed)
    -   `dev`: Development tools like Docker, Node.js, and the Gemini CLI.
    -   `rev`: Reverse engineering tools like Ghidra and Joern.
    -   `pwn`: Penetration testing tools and SSH hardening.
-   **Cross-Distro Support:** Works on Debian, Ubuntu, Kali, Parrot, and Arch Linux.
-   **Reproducible Environments:** A Docker-based testing system is included to validate the setup script on clean installations of Ubuntu, Arch, and Kali.
-   **Comprehensive Tooling:** Includes configurations for Zsh, Neovim (with Lua and lazy.nvim), Tmux, Alacritty, and more.

## Installation

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/mm4rks/dotfiles.git ~/.dotfiles
    ```

2.  **Run the setup script:**

    Change into the `~/.dotfiles` directory and execute the `setup.sh` script with the desired profiles.

    ```bash
    cd ~/.dotfiles
    chmod +x setup.sh
    ```

    **Examples:**

    -   **Default installation:**
        ```bash
        ./setup.sh
        ```

    -   **Default + Developer tools:**
        ```bash
        ./setup.sh dev
        ```

    -   **Install everything and harden SSH:**
        ```bash
        # Replace "ssh-ed25519 AAAA..." with your actual public key
        ./setup.sh all --ssh-key "ssh-ed25519 AAAA..."
        ```

## Profiles

-   **`default`**: (Implicitly installed)
    -   Core utilities: `git`, `zsh`, `tmux`, `eza`, `bat`, `fzf`, `ripgrep`.
    -   Neovim (latest AppImage) with a custom Lua configuration.
    -   Nerd Font (FiraMono).
    -   Stows configuration for `zsh`, `tmux`, `git`, `nvim`, etc.

-   **`dev`**:
    -   Docker and Docker Compose.
    -   Node.js (LTS) and `pure-prompt`.
    -   Gemini CLI (`@google/gemini-cli@nightly`).

-   **`rev`**:
    -   Ghidra, Joern, Semgrep, and `flare-floss`.
    -   Requires JDK 21 (will be installed automatically).

-   **`pwn`**:
    -   NetExec.
    -   SSH server hardening (disables password authentication). Requires providing a public key via the `--ssh-key` flag.

## Testing

The integrity of the `setup.sh` script is verified across multiple distributions using Docker. The `test_runner.sh` script automates this process.

To run the tests:

```bash
./test_runner.sh
```

This will build Docker images for Ubuntu, Arch, and Kali, and then execute the `setup.sh` script within each container to ensure it completes successfully.

## Managing Dotfiles with Stow

[GNU Stow](https://www.gnu.org/software/stow/) is used to manage symlinks for the configuration files.

-   **Create symlinks:**
    ```bash
    # Stow all packages
    stow zsh tmux git nvim alacritty ...

    # Stow a specific package
    stow nvim
    ```

-   **Remove symlinks:**
    ```bash
    # Un-stow all packages
    stow -D zsh tmux git nvim alacritty ...

    # Un-stow a specific package
    stow -D nvim
    ```