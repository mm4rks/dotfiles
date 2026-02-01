
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
HISTFILE=~/.zsh_history     # Set path for the history file.
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
# Add Docker completions to fpath
if [ -d /usr/share/zsh/vendor-completions ]; then
  fpath=(/usr/share/zsh/vendor-completions $fpath)
fi
autoload -Uz compinit       # Autoload the completion initialization utility.
compinit -d ~/.cache/zcompdump # Initialize completions, caching to this file.
zstyle ':completion:*:*:*:*:*' tag-order options arguments files
zstyle ':completion:*' completer _files _expand _complete _ignored _approximate
zstyle ':completion:*' matcher-list '' 'm:{[:lower:]}={[:upper:]}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' max-errors 2 # Allow up to 2 errors for fuzzy matching.
zstyle ':completion:*' menu select              # Enable a selectable completion menu.
zstyle ':completion:*' use-compctl false         # Use newer completion system instead of `compctl`.
zstyle ':completion:*' rehash true               # Automatically find new executables.
zstyle ':completion:*' verbose true
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'


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

source ~/.zsh_env.sh
eval "$(mise activate zsh)"
eval "$(mise completion zsh)"
source ~/.zsh_alias.sh
source ~/.zsh_docker.sh
source ~/.zsh_functions.sh
source ~/.zsh_plugins.sh

# source from zsh_plugins.sh
source_if_exists /etc/zsh_command_not_found
source_autosuggestions
source_syntax_highlighting

    

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

# Function to find and load pure prompt
# --- Prompt ---
# 1. Define candidate directories (Manual & System)
_pure_sources=(
    "$HOME/.zsh/pure"
    "/usr/lib/node_modules/pure-prompt"
)

# 2. Add dynamic Mise path if found
# We search for 'pure.zsh' inside the mise installs directory
if [ -d "$HOME/.local/share/mise/installs" ]; then
    _mise_pure_path=$(find "$HOME/.local/share/mise/installs" -maxdepth 6 -type f -name "pure.zsh" 2>/dev/null | head -n 1)
    if [ -n "$_mise_pure_path" ]; then
        # Prepend the mise directory to the list to give it priority
        _pure_sources=("$(dirname "$_mise_pure_path")" "${_pure_sources[@]}")
    fi
fi

_pure_prompt_found=false

# 3. Iterate and Load
for _pure_source in "${_pure_sources[@]}"; do
    # Check for the main file
    if [ -f "$_pure_source/pure.zsh" ]; then
        fpath+=("$_pure_source")
        
        # VALIDATION: promptinit requires a file named 'prompt_pure_setup'.
        # If Mise installed it as 'pure.zsh' only, we must symlink it for promptinit to work.
        if [ ! -f "$_pure_source/prompt_pure_setup" ]; then
             ln -sf "$_pure_source/pure.zsh" "$_pure_source/prompt_pure_setup"
        fi
        
        # VALIDATION: Pure requires async.zsh.
        # If it is named 'async.zsh', we must symlink it to 'async' for autoload to find it.
        if [ -f "$_pure_source/async.zsh" ] && [ ! -f "$_pure_source/async" ]; then
             ln -sf "$_pure_source/async.zsh" "$_pure_source/async"
        fi

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
unset _mise_pure_path _pure_sources _pure_source _pure_prompt_found
