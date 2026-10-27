#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

JADX_VERSION="1.5.5"
JADX_URL="https://github.com/skylot/jadx/releases/download/v${JADX_VERSION}/jadx-${JADX_VERSION}.zip"
JADX_SHA256="38a5766d3c8170c41566b4b13ea0ede2430e3008421af4927235c2880234d51a"
INSTALL_DIR="${LOCAL_PREFIX}/share/jadx"
BIN_DIR="${LOCAL_PREFIX}/bin"
VERSION_FILE="${INSTALL_DIR}/.dotfiles-version"

main() {
    if [ "$(cat "$VERSION_FILE" 2>/dev/null)" = "$JADX_VERSION" ]; then
        log "jadx ${JADX_VERSION} is already installed, skipping."
        return 0
    fi

    local TEMP_DIR
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf '$TEMP_DIR'" RETURN

    log "Installing jadx ${JADX_VERSION}..."
    download_and_verify "$JADX_URL" "$TEMP_DIR/jadx.zip" "$JADX_SHA256"

    rm -rf "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR" "$BIN_DIR"
    unzip -q "$TEMP_DIR/jadx.zip" -d "$INSTALL_DIR"
    chmod +x "$INSTALL_DIR/bin/jadx" "$INSTALL_DIR/bin/jadx-gui"

    ln -sf "$INSTALL_DIR/bin/jadx" "$BIN_DIR/jadx"
    ln -sf "$INSTALL_DIR/bin/jadx-gui" "$BIN_DIR/jadx-gui"
    echo "$JADX_VERSION" > "$VERSION_FILE"

    log "jadx ${JADX_VERSION} installed."
}

main "$@"
