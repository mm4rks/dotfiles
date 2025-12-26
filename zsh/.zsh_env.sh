export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.fzf/bin:$PATH"

export XDG_CONFIG_HOME="$HOME/.config"

# Set default editor: prefer nvim, but fall back to vim
if command -v nvim &> /dev/null; then
    export EDITOR='nvim'
    export VISUAL='nvim'
else
    export EDITOR='vim'
    export VISUAL='vim'
fi

# Use bat as the man page pager, but only if it is installed
if command -v bat &> /dev/null; then
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    export MANROFFOPT="-c"
fi


VIVID_CACHE="$HOME/.config/vivid_colors"

if command -v vivid >/dev/null 2>&1; then
    export LS_COLORS="$(vivid generate catppuccin-mocha)"
elif [ -f "$VIVID_CACHE" ]; then
    export LS_COLORS="$(cat "$VIVID_CACHE")"
fi

