export PATH=$PATH:$HOME/.local/bin

# Set default editor: prefer nvim, but fall back to vim
if command -v nvim &> /dev/null; then
    export EDITOR='nvim'
    export VISUAL='nvim'
    export SUDO_EDITOR='nvim'
else
    export EDITOR='vim'
    export VISUAL='vim'
    export SUDO_EDITOR='vim'
fi

# Use bat as the man page pager, but only if it is installed
if command -v bat &> /dev/null; then
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    export MANROFFOPT="-c"
fi
