source_if_exists() {
    [ -f "$1" ] && source "$1"
} # Helper function to source a file only if it exists.

source_autosuggestions() {
    local locations=(
        "/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
        "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    )

    for l "${locations[@]}"; do
        if source_if_exists "$l"; then
            ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'
            return
        fi
    done
}

source_syntax_highlighting() {
    # Known paths for zsh-syntax-highlighting
    local locations=(
        "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
        "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    )

    for l in "${locations[@]}"; do
        if source_if_exists "$l"; then
            return
        fi
    done
}


