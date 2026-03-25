#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

install_base_deps() {
    log "Installing base dependencies..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq ca-certificates curl gnupg unzip git build-essential stow wget libfuse2 pipx libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev zsh libkrb5-dev cmake zsh-autosuggestions zsh-syntax-highlighting wl-clipboard xclip python3-dev

    # Kernel header package names vary across Debian/Ubuntu/Kali.
    local HEADER_PKG=""
    if apt-cache show linux-headers-generic >/dev/null 2>&1; then
        HEADER_PKG="linux-headers-generic"
    elif apt-cache show "linux-headers-$(uname -r)" >/dev/null 2>&1; then
        HEADER_PKG="linux-headers-$(uname -r)"
    elif apt-cache show linux-headers-amd64 >/dev/null 2>&1; then
        HEADER_PKG="linux-headers-amd64"
    fi

    if [ -n "$HEADER_PKG" ]; then
        apt-get install -y -qq "$HEADER_PKG"
    else
        warn "No compatible kernel headers package found. Skipping headers installation."
    fi
}

install_base_deps
