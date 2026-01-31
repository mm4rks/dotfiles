source_if_exists() {
    [ -f "$1" ] && source "$1"
} # Helper function to source a file only if it exists.

os_detect() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}
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

tmux_smart_detach() {
  if [[ -z "$BUFFER" ]]; then
    if [[ -n "$TMUX" ]]; then
      # INSIDE TMUX: Check pane count
      local num_panes=$(tmux list-panes | wc -l)
      if [[ "$num_panes" -gt 1 ]]; then
        # More than one pane, so just exit the current shell/pane
        builtin exit
      else
        # Last pane in the window, so detach the client
        tmux detach-client
      fi
    else
      # NOT IN TMUX: Close the shell normally
      builtin exit
    fi
  else
    # LINE NOT EMPTY: Delete character
    zle delete-char-or-list
  fi
}

zle -N tmux_smart_detach
bindkey '^D' tmux_smart_detach

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

PROMPT_EOL_MARK=""          # Hide the '%' character that appears at the end of lines.

_fix_cursor() {
    echo -ne '\e[6 q'
}
# Disable cursor blinking (0 = off, 1 = on)
ZLE_CURSOR_BLINK=0

precmd_functions+=(_fix_cursor)
# --- Prompt ---
# Load pure prompt if available, otherwise use a minimal fallback.
_pure_sources=(
    "$HOME/.zsh/pure"
    "/usr/lib/node_modules/pure-prompt"
)

for _pure_source in "${_pure_sources[@]}"; do
    if [ -f "$_pure_source/pure.zsh" ]; then
        fpath+=("$_pure_source")
        _pure_prompt_found=true
        break
    fi
done

if [ "$_pure_prompt_found" = true ]; then
    autoload -U promptinit; promptinit
    prompt pure
else
    local NEWLINE=$'\n'
    PROMPT="${NEWLINE}%F{blue}%~%f${NEWLINE}%(?.%F{white}.%F{red})%(#.#.\$)%f "
fi

unset _pure_sources _pure_source _pure_prompt_found
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^R' history-incremental-search-backward # Ctrl+R for history search.
bindkey ' ' magic-space                          # Space performs history expansion (e.g., '!!').
bindkey '^[[Z' undo                              # Shift+Tab to undo. TODO change this to undo in insert mode only
bindkey '^x^e' edit-command-line-tmux-float                 # Ctrl+X, Ctrl+E to open editor.
bindkey '\ef' forward-word # Alt-f
bindkey '\eb' backward-word # Alt-b
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

source ~/.zsh_alias.sh
source ~/.zsh_docker.sh
source ~/.zsh_env.sh
source ~/.zsh_functions.sh
source ~/.zsh_plugins.sh

# Initialize zoxide
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi

# Enable syntax highlighting for zsh
source_syntax_highlighting() {
    local os
    os=$(os_detect)

    if [[ "$os" == "arch" ]]; then
        source_if_exists /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    elif [[ "$os" == "debian" || "$os" == "parrot" ]]; then
        source_if_exists /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    fi
}
source_syntax_highlighting

# Activate mise for tool version management
eval "$(mise activate zsh)"
