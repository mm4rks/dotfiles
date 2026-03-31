
# --- General Shell Options ----------------------------------------------------
setopt interactivecomments  # Allow comments in the interactive shell.
setopt promptsubst          # Enable command substitution in the prompt.
setopt magicequalsubst      # Enable filename expansion for args like 'anything=expression'.
setopt notify               # Report background job status immediately.
setopt nonomatch            # Don't error if a glob pattern has no match.
setopt numericglobsort      # Sort filenames with numbers naturally (e.g., 1, 2, 10).

# --- Directory & Navigation ---------------------------------------------------
DIRSTACKSIZE=8              # Set the directory stack size.

setopt autopushd            # Make `cd` push the old directory onto the stack.
setopt extendedglob         # Enable more advanced globbing features.
setopt pushdminus           # Swap behavior of `pushd +N` and `pushd -N`.
setopt pushdsilent          # Don't print the directory stack after `pushd` or `popd`.
setopt pushdtohome          # Make `pushd` with no arguments go to the home directory.
setopt pushdignoredups      # Don't push directories that are already on the stack.
WORDCHARS=${WORDCHARS//\/} # Slashes and minus separate words

# --- History Configuration ----------------------------------------------------
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"     # Set path for the history file.
HISTSIZE=20000              # Max number of commands to keep in memory.
SAVEHIST=20000              # Max number of commands to save to the file.
setopt appendhistory        # Append to history, don't overwrite.
setopt incappendhistory     # Add commands to history immediately as they are run.
setopt sharehistory         # Share history instantly between running shells.
setopt histignoredups       # Don't save duplicate consecutive commands.
setopt histignorespace      # Don't save commands that start with a space.
setopt histverify           # Show history expansions before executing them.
# --- Smart detach ---
setopt ignore_eof


# --- Completion System --------------------------------------------------------
# Add custom completions to fpath
if [ -d "${ZDOTDIR:-$HOME}/.zsh_completions" ]; then
  fpath=("${ZDOTDIR:-$HOME}/.zsh_completions" $fpath)
fi

# Add Docker completions to fpath if they exist in standard locations
if [ -d /usr/share/zsh/vendor-completions ]; then
  fpath=(/usr/share/zsh/vendor-completions $fpath)
fi
autoload -Uz compinit       # Autoload the completion initialization utility.
# Use a dynamic cache location
_zsh_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$_zsh_cache_dir"
compinit -d "$_zsh_cache_dir/zcompdump" 
zstyle ':completion:*' completer _expand _complete _ignored _approximate _files
zstyle ':completion:*' matcher-list '' 'm:{[:lower:]}={[:upper:]}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' max-errors 2 # Allow up to 2 errors for fuzzy matching.
zstyle ':completion:*' menu select              # Enable a selectable completion menu.
zstyle ':completion:*' use-compctl false         # Use newer completion system instead of `compctl`.
zstyle ':completion:*' rehash true               # Automatically find new executables.
zstyle ':completion:*' verbose true
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# Docker completions
zstyle ':completion:*:*:docker:*' image-names yes
zstyle ':completion:*:*:docker-*:*' image-names yes
zstyle ':completion:*:*:docker:*' tag-order 'docker-images docker-repos docker-repos-with-tags docker-containers docker-networks docker-volumes' 'options' 'arguments'
zstyle ':completion:*:*:docker-*:*' tag-order 'docker-images docker-repos docker-repos-with-tags docker-containers docker-networks docker-volumes' 'options' 'arguments'


autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^R' history-incremental-search-backward # Ctrl+R for history search.
bindkey ' ' magic-space                          # Space performs history expansion (e.g., '!!').
bindkey '^[[Z' undo                              # Shift+Tab to undo.
bindkey '\ef' forward-word                       # Alt-f
bindkey '\eb' backward-word                      # Alt-b
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^F' autosuggest-accept
bindkey '^[[3~' delete-char

# More bash-like bindings
bindkey '^H' backward-delete-char   # Backspace
bindkey '^P' up-line-or-history     # Previous history
bindkey '^N' down-line-or-history   # Next history
bindkey '^W' backward-kill-word     # Delete word backward
bindkey '^U' kill-whole-line        # Delete from cursor to start of line
bindkey '^K' kill-line              # Delete from cursor to end of line
bindkey '^Y' yank                   # Paste (yank)
bindkey '\ed' kill-word             # Alt-d, delete word forward

source "${ZDOTDIR:-$HOME}/.zsh_env.sh"
eval "$(mise activate zsh)"
eval "$(mise completion zsh)"

# Set default editor: prefer nvim, but fall back to vim
# Checked after mise activate so mise-installed nvim is found
if command -v nvim &> /dev/null; then
    export EDITOR='nvim'
    export VISUAL='nvim'
else
    export EDITOR='vim'
    export VISUAL='vim'
fi

source "${ZDOTDIR:-$HOME}/.zsh_alias.sh"
source "${ZDOTDIR:-$HOME}/.zsh_docker.sh"
source "${ZDOTDIR:-$HOME}/.zsh_functions.sh"
source "${ZDOTDIR:-$HOME}/.zsh_plugins.sh"

# Load additional shell components if they exist
source_if_exists /etc/zsh_command_not_found

if command -v fzf &> /dev/null; then
    source <(fzf --zsh)
fi

if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi

# Register widgets from .zsh_functions.sh
zle -N tmux_smart_detach
zle -N edit-command-line-tmux-float
bindkey '^D' tmux_smart_detach
bindkey '^x^e' edit-command-line-tmux-float      # Ctrl+X, Ctrl+E to open editor.

# --- Prompt Configuration ---
PROMPT_EOL_MARK=""          # Hide the '%' character that appears at the end of lines.

_fix_cursor() {
    echo -ne '\e[6 q'
}

# Disable cursor blinking (0 = off, 1 = on)
ZLE_CURSOR_BLINK=0

precmd_functions+=(_fix_cursor)

# --- Prompt Loading (Pure) ---
# We prioritize locations where the prompt is already set up (symlinks created by install script)
_pure_search_dirs=(
    "$HOME/.local/share/mise/installs/npm-pure-prompt/latest/lib/node_modules/pure-prompt"
    "$HOME/.local/share/mise/installs/npm-pure-prompt"
    "$HOME/.local/share/mise/installs/pure/latest/pure.zsh"
    "${ZDOTDIR:-$HOME}/.zsh/pure"
    "/usr/share/zsh/pure"
    "/usr/lib/node_modules/pure-prompt"
    "/usr/local/lib/node_modules/pure-prompt"
)

_pure_prompt_found=false
for _dir in "${_pure_search_dirs[@]}"; do
    if [ -d "$_dir" ] && [ -f "$_dir/prompt_pure_setup" ]; then
        fpath+=("$_dir")
        _pure_prompt_found=true
        break
    elif [ -f "$_dir" ] && [[ "$_dir" == *".zsh" ]]; then
        # Handle single-file pure.zsh if promptinit isn't needed or if path is mise-specific
        fpath+=("$(dirname "$_dir")")
        _pure_prompt_found=true
        break
    fi
done

if [ "$_pure_prompt_found" = true ]; then
    autoload -U promptinit; promptinit
    prompt pure
else
    local NEWLINE=$'\n'
    PROMPT="${NEWLINE}%F{blue}%~%f${NEWLINE}%(?.%F{white}.%F{red})%(#.#.$)%f "
fi
unset _pure_search_dirs _dir _pure_prompt_found
