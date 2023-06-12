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
source ~/.zshrc.export
source ~/.zshrc.function
source ~/.zshrc.alias
source ~/.zshrc.docker

function zvm_after_init() {
    [ -f ~/.plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh ] && source ~/.plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
}
ZVM_VI_INSERT_ESCAPE_BINDKEY=kj
[ -f ~/.plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh ] && source ~/.plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh
