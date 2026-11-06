# Dotfiles

Automated development environment setup for Ubuntu/Kali distributions, plus configuration stowing on Omarchy.

## Quick Start

### Standard Setup (Ubuntu/Kali or Omarchy)
On Ubuntu/Kali, requires sudo privileges and performs full system configuration, Mise tool installation, and dotfile stowing. On Omarchy, skips system/Mise installers and only stows the relevant configurations and syncs Neovim plugins.

```bash
git clone https://github.com/mm4rks/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup.sh
```

### Guest Mode (Ubuntu/Kali)
Sandboxed environment. No sudo required. Does not modify the host home directory.

```bash
git clone https://github.com/mm4rks/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
source activate.sh
```

## Profiles (./setup.sh [profiles] on Ubuntu/Kali)

- **dev**: Go, Rust.
- **pwn**: BloodHound, NetExec, PowerView, Certipy.
- **rev**: Joern, Ghidra, jadx, apktool, apkleaks, semgrep, flare-capa.
- **ssh**: SSH hardening.

## Testing

Run tests across all supported distributions using Docker:

```bash
./test_runner.sh
```
