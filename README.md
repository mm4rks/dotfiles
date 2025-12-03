# Installation

This setup script will install necessary packages and symlink the configuration files into your home directory.

```bash
git clone https://github.com/mm4rks/dotfiles ~/.dotfiles
cd ~/.dotfiles && chmod +x setup.sh && ./setup.sh
```

## Remove symlinks

```bash
cd ~/.dotfiles && stow -D zsh tmux git zsh_plugins dockerfiles nvim
```
