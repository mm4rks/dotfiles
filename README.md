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

## Subtrees

```bash
git remote add remote-name <URL to Git repo>
git subtree add --prefix=folder/ remote-name <URL to Git repo> subtree-branchname
```




### zsh syntax highlight

```bash
git remote add zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting.git
git subtree add --prefix=zsh-syntax-highlighting/ https://github.com/zsh-users/zsh-syntax-highlighting.git master
git subtree pull --prefix=zsh-syntax-highlighting/ https://github.com/zsh-users/zsh-syntax-highlighting.git master
stow -S zsh-syntax-highlighting
```
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.config/zsh-syntax-highlighting

### fzf

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

### zsh vi mode

git clone https://github.com/jeffreytse/zsh-vi-mode.git $HOME/.zsh-vi-mode

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
