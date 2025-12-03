# Installation

## HTTPS

```bash
git clone https://github.com/mm4rks/dotfiles ~/.dotfiles
cd ~/.dotfiles && chmod +x setup.sh && ./setup.sh
```

## SSH

```bash
git clone git@github.com:mm4rks/dotfiles.git
cd ~/.dotfiles && chmod +x setup.sh && ./setup.sh
```

## Box setup

```bash
chsh -s $(which zsh)
```
## change hostname

```bash
NEW_NAME="new-server-name"; OLD_NAME=$(hostnamectl status --static); \
echo "Changing hostname to $NEW_NAME..."; \
sudo hostnamectl set-hostname "$NEW_NAME" && \
sudo sed -i "s/127\.0\.1\.1[[:space:]]\+$OLD_NAME/127.0.1.1 $NEW_NAME/g" /etc/hosts && \
echo "Verification:" && hostnamectl status | grep "Static hostname" && grep "127.0.1.1" /etc/hosts
```

## Generate SSH Key

```bash
ssh-keygen -t ed25519
```

## Remove symlinks

```bash
cd ~/.dotfiles && stow -D zsh tmux git zsh_plugins dockerfiles nvim
```
