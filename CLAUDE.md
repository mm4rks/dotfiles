# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Automated development environment setup for Debian-based Linux distributions (Ubuntu, Kali). Uses GNU Stow for symlink management and Docker for cross-distribution CI testing. Two modes, chosen by `./setup.sh` (prompt) or passed as `persistent` / `guest`: **persistent** (full install, sudo required, stowed into `$HOME`) and **guest** (sandboxed in the gitignored `.guest/` dir, no sudo, no home directory modification).

This is the **`work`** branch: a lightweight variant of the ricing-focused `main` branch intended for work boxes. It has no Wayland/Hyprland desktop packages and no `mise` — terminal tools are installed as pinned binaries by `scripts/install_terminal_tools.sh` instead. Everything else (shell, tmux, nvim, the default security tools and the `pwn`/`ssh` profiles) is unchanged from `main`, except that the prompt is a native zsh prompt instead of starship (no git segment), because process startup is expensive on work boxes and the prompt must not fork.

## Commands

### Testing
```bash
# Full suite (Ubuntu, Kali, Kali guest mode)
./test_runner.sh

# Single distribution
docker build --target ubuntu-test       -t dotfiles-tester-ubuntu-test  -f Dockerfile.test .
docker build --target kali-test         -t dotfiles-tester-kali-test    -f Dockerfile.test .
docker build --target kali-guest-test   -t dotfiles-tester-kali-guest   -f Dockerfile.test .
```

### Linting
All `.sh` files must pass ShellCheck before committing. There is no automated pipeline — run manually from the repo root (picks up `.shellcheckrc`):
```bash
shellcheck -x *.sh scripts/*.sh
```
Use `# shellcheck disable=SCXXXX` only for confirmed false positives.

## Architecture

### Setup Flow
`./setup.sh [persistent|guest] [headless] [pwn] [ssh]` prompts for the mode if none is given (errors out without a TTY).

**Persistent** runs, in order:
1. `scripts/install_base_deps.sh`, `install_docker.sh`, `install_nerd_font.sh` (skipped with `headless`) — via sudo, apt only (`install_docker.sh` also handles pacman)
2. `scripts/install_terminal_tools.sh` — pinned-version binaries (neovim, zoxide, fzf, ripgrep, bat, eza, delta, fd, shellcheck, choose, node) into `~/.local/bin` / `~/.local/opt`, no root required
3. `scripts/stow_dotfiles.sh` — symlinks config packages to `$HOME`; `scripts/sync_nvim.sh` — installs plugins from `lazy-lock.json`
4. Default tools: Ghidra, Joern (sudo), jadx, apktool, trivy, dependency-check, pipx/npm tools
5. Profiles `pwn` (BloodHound, NetExec, PowerView, Certipy) and `ssh` (`harden_ssh.sh`, requires `authorized_keys`)

**Guest** sources `activate.sh` and runs only `install_terminal_tools.sh` and `sync_nvim.sh`. No sudo; host prerequisites (`curl tar xz git zsh`) are checked, not installed.

`activate.sh` is sourced (not executed, bash or zsh) for guest mode. It points `ZDOTDIR` at `zsh/` and `XDG_{CONFIG,CACHE,DATA,STATE}_HOME`, `DOTFILES_PREFIX` (install prefix) and `DOTFILES_GUEST_DIR` (shell history) into `.guest/`, so nothing lands in `$HOME` or in tracked repo files.

### Stow Packages
The following directories are stowed to `$HOME`: `zsh`, `tmux`, `eza`, `git`, `vivid`, `nvim`.

### Terminal Tools
`scripts/install_terminal_tools.sh` pins exact versions (hardcoded at the top of the script) and verifies each download against a sha256 checksum before installing, following the same `download_and_verify` convention as `scripts/install_ghidra.sh` etc. Bump a version by updating its `_VERSION`/`_SHA256` pair; a tool is reinstalled whenever the copy in `$LOCAL_PREFIX/bin` does not report the pinned version.

Every downloaded artifact is pinned and checksum-verified (jadx/apktool/dependency-check use a `.dotfiles-version` marker for idempotency; pipx/npm tools are pinned with `==`/`@`; the Trivy image is pinned by digest; nvim plugins by the committed `nvim/.config/nvim/lazy-lock.json`). Never add an unpinned or unverified download.

### Shared Script Library (`scripts/lib.sh`)
All scripts must source this. Key utilities:
- `log` / `warn` / `error` — colored output; `error` exits with status 1
- `command_exists <name>` — preferred over raw `command -v`
- `download_and_verify <url> <path> [sha256sum]` — safe downloads
- `user_in_group <group>` — group membership check (exact name)
- `LOCAL_PREFIX` — user-level install prefix (`~/.local`, or `.guest/local` in guest mode)

## Bash Script Conventions

- Strict mode required: `#!/bin/bash` + `set -euo pipefail`
- 4-space indentation; no tabs; `then`/`do` on same line as `if`/`for`/`while`
- `UPPER_CASE` globals, `local` for all function-scoped variables; always quote expansions
- Idempotent: check with `command_exists` before installing anything
- Cleanup temp dirs with `trap "rm -rf '$TEMP_DIR'" RETURN`
- Every script has a `main()` entry point called as `main "$@"`
- Don't pipe into `grep -q` under `pipefail` (early exit can SIGPIPE the producer); capture output first
- Determine repo root dynamically: `REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)`
- New tool installers go in `scripts/install_<tool_name>.sh`

## Sandbox / Guest Mode Constraints

In guest mode (and in the Claude Code sandbox), system-level operations **will always fail**. Never attempt `sudo`, `apt`, `stow`, `chown`, `chmod`, or host system inspection (`/etc/os-release`, `nvidia-smi`, etc.). If a system change is required, identify the exact command and ask the user to run it on the host.

## TTS Notifications

For long-running tasks, notify on completion:
```bash
~/.local/bin/tts "Task complete."
```
