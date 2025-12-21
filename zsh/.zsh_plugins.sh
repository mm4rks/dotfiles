source_if_exists() {
    [ -f "$1" ] && source "$1"
} # Helper function to source a file only if it exists.

if command -v fzf &> /dev/null; then
    source <(fzf --zsh)
fi
source_if_exists /etc/zsh_command_not_found

# zvm_after_init() {
#     if command -v fzf &> /dev/null; then
#         source <(fzf --zsh)
#     fi
#     source_if_exists /etc/zsh_command_not_found
#
#     if source_if_exists /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh; then
#         ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'
#     fi
# }

if command -v fzf &> /dev/null; then
    source <(fzf --zsh)
fi
source_if_exists /etc/zsh_command_not_found
source_autosuggestions() {
    local os
    os=$(os_detect)

    if [[ "$os" == "arch" ]]; then
        if source_if_exists /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh; then
            ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'
        fi
    elif [[ "$os" == "debian" || "$os" == "parrot" ]]; then
        if source_if_exists /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh; then
            ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'
        fi
    fi
}
source_autosuggestions

# source_if_exists ~/.plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh