# ------------------------------------------------------------------------------
# Zsh Plugins (Manual Loading)
# ------------------------------------------------------------------------------

source_if_exists() {
    [ -f "$1" ] && source "$1"
} # Helper function to source a file only if it exists.

zvm_config() {
    ZVM_SYSTEM_CLIPBOARD_ENABLED=true
    ZVM_CLIPBOARD_COPY_CMD='xclip -selection clipboard'
    ZVM_CLIPBOARD_PASTE_CMD='xclip -selection clipboard -o'
} # Define zsh-vi-mode config before sourcing the plugin.

source_if_exists ~/.plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh
source_if_exists /usr/share/fzf/key-bindings.zsh
source_if_exists /usr/share/fzf/completion.zsh
source_if_exists /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh # should be last
