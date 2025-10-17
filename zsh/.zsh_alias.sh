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

if command -v nvim &> /dev/null; then
    alias vim='nvim' # Conditional alias for Neovim
fi

if command -v bat &> /dev/null; then
    alias cat='bat --paging=never' # Conditional alias for bat
    alias less='bat'
fi
