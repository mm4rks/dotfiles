#!/bin/bash
read -p "Install packages? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "installing packages..."
    sudo apt update
    sudo apt install -y git
    sudo apt install -y stow
    sudo apt install -y tmux
    sudo apt install -y zsh
    sudo apt install -y curl
    sudo apt install -y wget
fi

read -p "Remove old dotfiles? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    rm ~/.zshrc* ~/.tmux.conf ~/.config/nvim/init.vim
    rm -rf ~/.config/nvim/lua/
fi

stow -S tmux zsh

read -p "Install nvim 0.5? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "installing nvim 0.5 from github release..."
    wget https://github.com/neovim/neovim/releases/download/v0.5.0/nvim.appimage
    chmod +x nvim.appimage
    sudo mv nvim.appimage /usr/local/bin/nvim
    stow -S nvim
    nvim +PlugInstall +COQdeps +qall
fi


read -p "Install fzf + zsh-syntax-highlighting? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.config/zsh-syntax-highlighting
    echo "installing fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install
fi

read -p "Install docker? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "installing docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
fi

read -p "Install jupyter? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "installing jupyter"
    if ! command -v pip3 &> /dev/null
    then
        echo "pip3 could not be found"
        exit 1
    fi
    pip3 install --user jupyterlab pandas
fi

read -p "Install GEF? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "installing gef/gdb..."
    sudo apt install gdb
    git clone https://github.com/hugsy/gef.git
    echo source `pwd`/gef/gef.py >> ~/.gdbinit
    if command -v pip3 &> /dev/null
    then
        pip3 install capstone unicorn keystone-engine ropper
    fi
fi
