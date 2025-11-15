alias d='dirs -v | head -5'
alias 1='cd -'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias cd..='cd ..'
alias ls='ls --color=auto'
alias la='ls -a'
alias ll='ls -la'
alias l='ls'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip --color=auto'
alias xargs='xargs '
alias xc="xclip -selection clipboard" # Alias for copying to the clipboard
alias ntlm.pw='function _ntlm(){ curl https://ntlm.pw/$1; }; _ntlm' # Fetches NTLM hashes from ntlm.pw for a given value
alias certipy='certipy-ad' # Alias for certipy-ad
if command -v eza &> /dev/null; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
fi

alias ff="fzf --preview 'bat --style=numbers --color=always {}'"

if command -v zoxide &> /dev/null; then
  alias cd="zd"
  zd() {
    if [ $# -eq 0 ]; then
      builtin cd ~ && return
    elif [ -d "$1" ]; then
      builtin cd "$1"
    else
      z "$@" && printf "\U000F17A9 " && pwd || echo "Error: Directory not found"
    fi
  }
fi

open() {
  xdg-open "$@" >/dev/null 2>&1 &
}

# Directories
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Tools
alias d='docker'
alias r='rails'
n() { if [ "$#" -eq 0 ]; then nvim .; else nvim "$@"; fi; }

# Git
alias g='git'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'

# if command -v nvim &> /dev/null; then
#     alias vim='nvim' # Conditional alias for Neovim
# fi

if command -v batcat &> /dev/null; then
    alias bat='batcat'
fi

if command -v bat &> /dev/null; then
    alias cat='bat --paging=never' # Conditional alias for bat
    alias less='bat'
fi
alias devdocs="docker run --name devdocs -d -p 9292:9292 ghcr.io/freecodecamp/devdocs:latest"
