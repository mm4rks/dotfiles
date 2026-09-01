# Dotfiles (work branch)

Automated development environment setup for Debian and Arch-based distributions.

Lightweight variant of the `main` branch for work boxes: terminal tools (shell, tmux, nvim, starship, etc.) with no Wayland/Hyprland desktop and no `mise` — see `CLAUDE.md` for details.

## Quick Start

### Standard Setup
Requires sudo privileges. Performs full system configuration and stows dotfiles.

```bash
git clone https://github.com/mm4rks/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup.sh
```

### Guest Mode
Sandboxed environment. No sudo required. Does not modify the host home directory.

```bash
git clone https://github.com/mm4rks/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
source activate.sh
```

## Default Tools

Installed by `./setup.sh` regardless of profile: Ghidra, Joern, jadx, apktool, trivy, dependency-check, semgrep, flare-capa, apkleaks, cdxgen.

## Profiles (./setup.sh [profiles])

- **pwn**: BloodHound, NetExec, PowerView, Certipy.
- **ssh**: SSH hardening.

## Testing

Run tests across all supported distributions using Docker:

```bash
./test_runner.sh
```
