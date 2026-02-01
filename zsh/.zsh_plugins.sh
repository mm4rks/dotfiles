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

source_autosuggestions() {
    local plugin_path

    # Prioritize mise installation
    plugin_path="$HOME/.mise/installs/zsh-autosuggestions/latest/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    if [ -f "$plugin_path" ]; then
        source "$plugin_path"
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'
        return
    fi

    # Fallback to system-wide installations based on OS
    local os=$(os_detect)
    case "$os" in
        "arch")
            plugin_path="/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
            ;;
        "debian"|"parrot")
            plugin_path="/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
            ;;
        *)
            return # No known path for other OS
            ;;
    esac

    if [ -f "$plugin_path" ]; then
        source "$plugin_path"
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'
    fi
}

source_syntax_highlighting() {
    local plugin_path

    # Prioritize mise installation
    plugin_path="$HOME/.mise/installs/zsh-syntax-highlighting/latest/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    if [ -f "$plugin_path" ]; then
        source "$plugin_path"
        return
    fi

    # Fallback to system-wide installations based on OS
    local os=$(os_detect)
    case "$os" in
        "arch")
            plugin_path="/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
            ;;
        "debian"|"parrot")
            plugin_path="/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
            ;;
        *)
            return # No known path for other OS
            ;;
    esac

    if [ -f "$plugin_path" ]; then
        source "$plugin_path"
    fi
}

if command -v fzf &> /dev/null; then
    source <(fzf --zsh)
fi

if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi

source_if_exists /etc/zsh_command_not_found
source_autosuggestions
source_syntax_highlighting
