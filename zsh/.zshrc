# The following lines were added by compinstall

zstyle ':completion:*' completer _expand _complete _ignored _approximate
zstyle ':completion:*' matcher-list '' 'm:{[:lower:]}={[:upper:]}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' max-errors 3
zstyle :compinstall filename '$HOME/.zshrc'

autoload zmv
autoload -Uz compinit
compinit
autoload -z edit-command-line
zle -N edit-command-line
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
PROMPT=" %B%(?.%F{251}.%F{red})$%f%b "
RPROMPT=" %F{blue}%~%f "
DIRSTACKSIZE=8
setopt GLOB_DOTS
setopt autocd autopushd extendedglob notify
setopt pushdminus pushdsilent pushdtohome pushdignoredups
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY
# Enable vi mode
bindkey -v
bindkey '^R' history-incremental-search-backward
bindkey "^X^E" edit-command-line
source ~/.zsh_env.sh
source ~/.zsh_functions.sh
source ~/.zsh_alias.sh
source ~/.zsh_docker.sh
source ~/.zsh_plugins.sh
