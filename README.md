# Dotfiles

Automated development environment setup for Debian and Arch-based distributions.

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

## Profiles (./setup.sh [profiles])

- **dev**: Go, Rust.
- **pwn**: BloodHound, NetExec, PowerView, Certipy.
- **rev**: Joern, Ghidra.

## Testing

Run tests across all supported distributions using Docker:

```bash
./test_runner.sh
```
