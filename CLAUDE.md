# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Automated development environment setup for Debian and Arch-based Linux distributions. Uses GNU Stow for symlink management, Mise for tool version pinning, and Docker for cross-distribution CI testing. Two modes: **standard** (full install, sudo required) and **guest** (sandboxed, no sudo, no home directory modification).

## Commands

### Testing
```bash
# Full suite (Ubuntu, Kali, Parrot)
./test_runner.sh

# Single distribution
docker build --target ubuntu-test       -t dotfiles-tester-ubuntu-test  -f Dockerfile.test .
docker build --target kali-test         -t dotfiles-tester-kali-test    -f Dockerfile.test .
docker build --target kali-guest-test   -t dotfiles-tester-kali-guest   -f Dockerfile.test .
docker build --target parrot-test       -t dotfiles-tester-parrot-test  -f Dockerfile.test .
```

### Linting
All `.sh` files must pass ShellCheck before committing. There is no automated pipeline — run manually:
```bash
shellcheck scripts/<script_name>.sh
```
Use `# shellcheck disable=SCXXXX` only for confirmed false positives.

## Architecture

### Setup Flow
`setup.sh` orchestrates four phases in order:
1. `scripts/install_base_deps.sh` — system packages (apt/pacman)
2. `scripts/install_docker.sh` — Docker + optional NVIDIA toolkit
3. `scripts/configure_mise.sh` — merges `mise/base.toml` + profile TOMLs, installs all tools
4. `scripts/stow_dotfiles.sh` — symlinks config packages to `$HOME`

`bootstrap.sh` is a convenience wrapper that calls `setup.sh` with `pwn ssh` profiles.

`activate.sh` is sourced (not executed) for guest mode — sets `ZDOTDIR` and `XDG_CONFIG_HOME` to point into the repo instead of using Stow.

### Stow Packages
The following directories are stowed to `$HOME`: `zsh`, `tmux`, `eza`, `git`, `vivid`, `nvim`, `opencode`, `voxtype`. Wayland-specific (`alacritty`, `hypr`, `kanshi`, `waybar`) are stowed separately.

### Mise Tool Management
`mise/base.toml` pins core tools (Neovim, Node, Python, fzf, ripgrep, bat, delta, zoxide, etc.). Profile-specific tools are in `mise/dev.profile` (Go, Rust), `mise/rev.profile` (Java, semgrep, flare-capa). `scripts/configure_mise.sh` merges these into a single config before installing.

### Shared Script Library (`scripts/lib.sh`)
All scripts must source this. Key utilities:
- `log` / `warn` / `error` — colored output; `error` exits with status 1
- `command_exists <name>` — preferred over raw `command -v`
- `download_and_verify <url> <path> [sha256sum]` — safe downloads
- `user_in_group <group>` — group membership check

## Bash Script Conventions

- Strict mode required: `#!/bin/bash` + `set -euo pipefail`
- 4-space indentation; no tabs; `then`/`do` on same line as `if`/`for`/`while`
- `UPPER_CASE` globals, `local` for all function-scoped variables; always quote expansions
- Idempotent: check with `command_exists` before installing anything
- Cleanup temp dirs with `trap "rm -rf '$TEMP_DIR'" RETURN`
- Every script has a `main()` entry point called as `main "$@"`
- Determine repo root dynamically: `REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)`
- New tool installers go in `scripts/install_<tool_name>.sh`

## Sandbox / Guest Mode Constraints

In guest mode (and in the Claude Code sandbox), system-level operations **will always fail**. Never attempt `sudo`, `apt`, `stow`, `chown`, `chmod`, or host system inspection (`/etc/os-release`, `nvidia-smi`, etc.). If a system change is required, identify the exact command and ask the user to run it on the host.

## TTS Notifications

For long-running tasks, notify on completion:
```bash
/home/node/.local/bin/tts "Task complete."
```
