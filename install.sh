sudo apt update
sudo apt install -y git
sudo apt install -y stow
sudo apt install -y tmux
sudo apt install -y zsh
sudo apt install -y curl
sudo apt install -y wget

# install nvim 0.5 from github release
wget https://github.com/neovim/neovim/releases/download/v0.5.0/nvim.appimage
chmod +x nvim.appimage
sudo mv nvim.appimage /usr/local/bin/nvim

stow -S tmux zsh nvim
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.config/zsh-syntax-highlighting

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

if ! command -v pip3 &> /dev/null
then
    echo "pip3 could not be found"
    exit 1
fi

# pip3 install capstone unicorn keystone-engine ropper
# pip3 install jupyterlab pandas
