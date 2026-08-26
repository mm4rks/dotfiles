# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Automated development environment setup for Debian and Arch-based Linux distributions. Uses GNU Stow for symlink management and Docker for cross-distribution CI testing. Two modes: **standard** (full install, sudo required) and **guest** (sandboxed, no sudo, no home directory modification).

This is the **`work`** branch: a lightweight variant of the ricing-focused `main` branch intended for work boxes. It has no Wayland/Hyprland desktop packages and no `mise` — terminal tools are installed as pinned binaries by `scripts/install_terminal_tools.sh` instead. Everything else (shell, tmux, nvim, starship, and the `pwn`/`rev`/`ssh` security-tooling profiles) is unchanged from `main`.

## Commands

### Testing
```bash
# Full suite (Ubuntu, Kali, Parrot)
./test_runner.sh

# Single distribution
docker build --target ubuntu-test       -t dotfiles-tester-ubuntu-test  -f Dockerfile.test .
docker build --target kali-test         -t dotfiles-tester-kali-test    -f Dockerfile.test .
docker build --target kali-guest-test   -t dotfiles-tester-kali-guest   -f Dockerfile.test .
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
3. `scripts/install_terminal_tools.sh` — downloads pinned-version binaries (neovim, starship, zoxide, fzf, ripgrep, bat, eza, delta, fd, shellcheck, choose, node) into `~/.local/bin` / `~/.local/opt`, no root required
4. `scripts/stow_dotfiles.sh` — symlinks config packages to `$HOME`

`bootstrap.sh` is a convenience wrapper that calls `setup.sh` with `pwn ssh` profiles.

`activate.sh` is sourced (not executed) for guest mode — sets `ZDOTDIR` and `XDG_CONFIG_HOME` to point into the repo instead of using Stow.

### Stow Packages
The following directories are stowed to `$HOME`: `zsh`, `tmux`, `eza`, `git`, `vivid`, `nvim`, `voxtype`, `starship`.

### Terminal Tools
`scripts/install_terminal_tools.sh` pins exact versions (hardcoded at the top of the script) and verifies each download against a sha256 checksum before installing, following the same `download_and_verify` convention as `scripts/install_ghidra.sh` etc. Bump a version by updating its `_VERSION`/`_SHA256` pair.

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
