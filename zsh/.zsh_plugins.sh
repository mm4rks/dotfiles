# zsh/.zsh_plugins.sh: Plugin loading utility and search paths

source_if_exists() {
    [ -f "$1" ] && source "$1"
}

# Generic plugin loader that searches common system and user paths.
# Usage: load_plugin "plugin-name" "script-to-source.zsh"
load_plugin() {
    local name="$1"
    local script="$2"
    local search_paths=(
        "/usr/share/zsh/plugins/$name/$script"
        "/usr/share/$name/$script"
        "/usr/local/share/$name/$script"
        "$HOME/.zsh/$name/$script"
        "$HOME/.zsh/plugins/$name/$script"
    )

    for p in "${search_paths[@]}"; do
        if [ -f "$p" ]; then
            source "$p"
            return 0
        fi
    done
    return 1
}

# Load standard plugins if available
# Bind autosuggest widgets once instead of re-binding on every precmd (slow).
# Safe because syntax-highlighting is loaded after it and no widgets are added later.
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=100 # Skip suggestions for long/pasted buffers.
load_plugin "zsh-autosuggestions" "zsh-autosuggestions.zsh" && ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'
ZSH_HIGHLIGHT_MAXLENGTH=512 # Skip highlighting for long/pasted buffers.
load_plugin "zsh-syntax-highlighting" "zsh-syntax-highlighting.zsh"
