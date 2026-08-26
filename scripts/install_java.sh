#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

install_java() {
    local REQUIRED_VERSION="21"
    log "Checking for Java ${REQUIRED_VERSION}..."

    local java_version=""
    local java_bin_dir=""
    if command_exists java; then
        # Capture major version (e.g., "21" from "21.0.4")
        java_version=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}' | cut -d. -f1)
        # Fallback for different java -version formats
        if [ -z "$java_version" ]; then
            java_version=$(java -version 2>&1 | head -n 1 | awk '{print $3}' | tr -d '"' | cut -d. -f1)
        fi
        java_bin_dir="$(dirname "$(readlink -f "$(command -v java)")")"
    fi

    # A JRE-only install (e.g. pulled in as another package's dependency)
    # satisfies the version check above but lacks javac, which tools like
    # Ghidra require. Check for javac right next to the *actual* java
    # binary being used, not just anywhere on PATH -- a stray unrelated
    # javac elsewhere on PATH must not mask a missing one here.
    if [ "$java_version" != "$REQUIRED_VERSION" ] || [ ! -x "${java_bin_dir}/javac" ]; then
        log "Installing OpenJDK ${REQUIRED_VERSION}..."
        apt-get update -qq && apt-get install -y -qq "openjdk-${REQUIRED_VERSION}-jdk"
    else
        log "Java ${REQUIRED_VERSION} (JDK) is already installed."
    fi
}

export_java_home() {
    local java_home
    java_home="$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")"

    if [ -z "$java_home" ] || [ ! -d "$java_home" ]; then
        warn "Could not resolve JAVA_HOME. Skipping bashrc export."
        return 0
    fi

    local target_user="${SUDO_USER:-$(whoami)}"
    local target_home
    target_home="$(getent passwd "$target_user" | cut -d: -f6)"

    if [ -z "$target_home" ] || [ ! -d "$target_home" ]; then
        warn "Could not resolve home directory for ${target_user}. Skipping bashrc export."
        return 0
    fi

    local bashrc="${target_home}/.bashrc"
    local start_marker="# >>> dotfiles JAVA_HOME >>>"
    local end_marker="# <<< dotfiles JAVA_HOME <<<"

    touch "$bashrc"
    if grep -qF "$start_marker" "$bashrc"; then
        sed -i "/${start_marker}/,/${end_marker}/d" "$bashrc"
    fi

    {
        echo "$start_marker"
        echo "export JAVA_HOME=\"${java_home}\""
        echo "$end_marker"
    } >> "$bashrc"
    chown "$target_user":"$target_user" "$bashrc"

    log "Exported JAVA_HOME=${java_home} in ${bashrc}."
}

main() {
    if [[ $EUID -ne 0 ]]; then
       error "This script must be run as root (use sudo)."
    fi
    install_java
    export_java_home
}

main "$@"
