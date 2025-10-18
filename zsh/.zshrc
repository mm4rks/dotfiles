# ------------------------------------------------------------------------------
# Zsh Configuration
# ------------------------------------------------------------------------------

# --- General Shell Options ----------------------------------------------------
setopt interactivecomments  # Allow comments in the interactive shell.
setopt promptsubst          # Enable command substitution in the prompt.
setopt magicequalsubst      # Enable filename expansion for args like 'anything=expression'.
setopt notify               # Report background job status immediately.
setopt nonomatch            # Don't error if a glob pattern has no match.
setopt numericglobsort      # Sort filenames with numbers naturally (e.g., 1, 2, 10).

# --- Directory & Navigation ---------------------------------------------------
DIRSTACKSIZE=8              # Set the directory stack size.
setopt autocd               # Change directory just by typing the dir name.
setopt autopushd            # Make `cd` push the old directory onto the stack.
setopt extendedglob         # Enable more advanced globbing features.
setopt pushdminus           # Swap behavior of `pushd +N` and `pushd -N`.
setopt pushdsilent          # Don't print the directory stack after `pushd` or `popd`.
setopt pushdtohome          # Make `pushd` with no arguments go to the home directory.
setopt pushdignoredups      # Don't push directories that are already on the stack.
WORDCHARS=${WORDCHARS//\/-} # Slashes and minus separate words

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

# --- Completion System --------------------------------------------------------
autoload -Uz compinit       # Autoload the completion initialization utility.
compinit -d ~/.cache/zcompdump # Initialize completions, caching to this file.
zstyle ':completion:*:*:*:*:*' tag-order arguments options files
zstyle ':completion:*' completer _expand _complete _ignored _approximate
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

bindkey -v                  # Enable Vi mode for command-line editing.

PROMPT_EOL_MARK=""          # Hide the '%' character that appears at the end of lines.

#bindkey '^R' history-incremental-search-backward # Ctrl+R for history search.
bindkey ' ' magic-space                          # Space performs history expansion (e.g., '!!').
bindkey '^[[Z' undo                              # Shift+Tab to undo. TODO change this to undo in insert mode only
bindkey -s -M vicmd '^?' 'ciw'                   # Backspace executes 'change inner word'.

# Widget to edit the current command line in your default editor ($EDITOR).
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey "^X^E" edit-command-line                 # Ctrl+X, Ctrl+E to open editor.
bindkey '^N' forward-word

source .zsh_alias.sh
source .zsh_docker.sh
source .zsh_env.sh
source .zsh_functions.sh
source .zsh_plugins.sh


