# Ensure ~/.local/bin is in PATH but preserve existing paths
export PATH="$HOME/.local/bin:$PATH"
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# Only set XDG_CONFIG_HOME if it hasn't been redirected (e.g. for sandbox)
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Use bat as the man page pager, but only if it is installed
if command -v bat &> /dev/null; then
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    export MANROFFOPT="-c"
elif command -v batcat &> /dev/null; then
    export MANPAGER="sh -c 'col -bx | batcat -l man -p'"
    export MANROFFOPT="-c"
fi

# vivid output only depends on the theme; generate once and reuse.
VIVID_CACHE="$HOME/.config/vivid_colors"
if [[ ! -s $VIVID_CACHE ]] && (( $+commands[vivid] )); then
    vivid generate catppuccin-mocha >| "$VIVID_CACHE"
fi
[[ -s $VIVID_CACHE ]] && export LS_COLORS="$(<"$VIVID_CACHE")"

# Newest /usr/lib/jvm/java-* directory (numeric sort, symlinks excluded).
if [[ -z ${JAVA_HOME:-} ]]; then
    _java_home=(/usr/lib/jvm/java-*(N/n[-1]))
    (( $#_java_home )) && export JAVA_HOME="$_java_home[1]"
    unset _java_home
fi
