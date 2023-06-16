# My Linux Setup

## Packages

```bash
sudo apt update
sudo apt install -y git
sudo apt install -y stow
sudo apt install -y tmux
sudo apt install -y zsh
sudo apt install -y curl
sudo apt install -y wget
sudo apt install -y python3-pip
sudo apt install -y python3-venv
```

## Plugins


```bash
# zsh syntax highlight, zsh vim mode, fzf
mkdir -p ~/.plugins
git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.plugins/zsh-syntax-highlighting
git clone --depth 1 https://github.com/jeffreytse/zsh-vi-mode.git ~/.plugins/zsh-vi-mode
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.plugins/fzf
~/.plugins/fzf/install
```

## Other

### neovim

https://github.com/neovim/neovim/releases/

### docker

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
less get-docker.sh
sh get-docker.sh
rm get-docker.sh
```

### alacritty

```bash
sudo apt install cargo
cargo install alacritty
# mv .desktop and png TODO
```

### nextcloud

# Enable

```bash
stow -S <package>
```


```bash
stow -S tmux zsh nvim
```
