#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

JADX_VERSION="1.5.5"
JADX_URL="https://github.com/skylot/jadx/releases/download/v${JADX_VERSION}/jadx-${JADX_VERSION}.zip"
INSTALL_DIR="${HOME}/.local/share/jadx"
BIN_DIR="${HOME}/.local/bin"

main() {
    if command_exists jadx; then
        log "jadx already installed at $(command -v jadx), skipping."
        return 0
    fi

    local TEMP_DIR
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf '$TEMP_DIR'" RETURN

    log "Installing jadx ${JADX_VERSION}..."
    download_and_verify "$JADX_URL" "$TEMP_DIR/jadx.zip"

    rm -rf "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR" "$BIN_DIR"
    unzip -q "$TEMP_DIR/jadx.zip" -d "$INSTALL_DIR"
    chmod +x "$INSTALL_DIR/bin/jadx" "$INSTALL_DIR/bin/jadx-gui"

    ln -sf "$INSTALL_DIR/bin/jadx" "$BIN_DIR/jadx"
    ln -sf "$INSTALL_DIR/bin/jadx-gui" "$BIN_DIR/jadx-gui"

    log "jadx ${JADX_VERSION} installed."
}

main "$@"
