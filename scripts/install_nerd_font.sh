#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip"
# This checksum is for v3.2.1 of JetBrainsMono.zip
FONT_SHA256="6596922aabaf8876bb657c36a47009ac68c388662db45d4ac05c2536c2f07ade"

install_jetbrains_mono_nerd_font() {
    log "Installing JetBrainsMono Nerd Font..."

    if ! command_exists fc-cache; then
        warn "fc-cache not found. Skipping JetBrainsMono Nerd Font installation."
        return 0
    fi

    local FONT_DIR="/usr/local/share/fonts/NerdFonts"
    if fc-list | grep -qi "JetBrainsMono" && fc-list | grep -qi "Nerd Font"; then
        log "JetBrainsMono Nerd Font already appears to be installed (detected by fc-list). Skipping."
        return 0
    fi
    if [ -d "$FONT_DIR" ] && find "$FONT_DIR" -maxdepth 1 -iname "JetBrainsMono*.ttf" -print -quit | grep -q .; then
        log "JetBrainsMono font files already exist in $FONT_DIR. Assuming installed. Skipping."
        return 0
    fi

    local TEMP_DIR
    TEMP_DIR="$(mktemp -d)"
    trap "rm -rf '$TEMP_DIR'" RETURN

    local FONT_ZIP="JetBrainsMono.zip"

    mkdir -p "$FONT_DIR"

    download_and_verify "$FONT_URL" "${TEMP_DIR}/$FONT_ZIP" "$FONT_SHA256"

    log "Unzipping font to $FONT_DIR..."
    if ! unzip -q -o "${TEMP_DIR}/$FONT_ZIP" -d "$FONT_DIR"; then
        warn "Failed to unzip JetBrainsMono Nerd Font. Cleanup may be required."
        return 1
    fi
    
    fc-cache -fv > /dev/null
    log "JetBrainsMono Nerd Font installed and cache refreshed."
}

main() {
    if [[ $EUID -ne 0 ]]; then
       error "This script must be run as root (use sudo)."
    fi
    install_jetbrains_mono_nerd_font
}

main "$@"
