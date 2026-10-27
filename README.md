# Dotfiles (work branch)

Automated development environment setup for Debian-based distributions (Ubuntu, Kali).

Lightweight variant of the `main` branch for work boxes: terminal tools (shell, tmux, nvim, etc.) with no Wayland/Hyprland desktop and no `mise` — see `CLAUDE.md` for details.

## Quick Start

```bash
git clone -b work https://github.com/mm4rks/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup.sh            # asks: persistent or guest
```

The mode can also be passed directly: `./setup.sh persistent [profiles]` or `./setup.sh guest`.

### Persistent
Requires sudo. Installs system packages and tools, sets zsh as login shell, and stows the dotfiles into `$HOME`.

### Guest
Sandboxed. No sudo, nothing written to `$HOME`. Installs the terminal tools and nvim plugins into the gitignored `.guest/` directory of the repo; shell history, caches and configs live there too. Requires `curl tar xz git zsh` on the host.

```bash
./setup.sh guest
source activate.sh && exec zsh
```

## Default Tools (persistent mode)

Ghidra, Joern, jadx, apktool, trivy (Docker wrapper), dependency-check, semgrep, flare-capa, apkleaks, cdxgen. All versions are pinned and downloads are checksum-verified.

## Profiles (persistent mode: `./setup.sh persistent [profiles]`)

- **headless**: skip the Nerd Font.
- **pwn**: BloodHound, NetExec, PowerView, Certipy.
- **ssh**: install openssh-server and disable password/root login. Refuses to run unless `~/.ssh/authorized_keys` exists.

## Testing

Run tests across all supported distributions using Docker:

```bash
./test_runner.sh
```
