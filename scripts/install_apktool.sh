#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

APKTOOL_VERSION="3.0.2"
JAR_URL="https://github.com/iBotPeaches/Apktool/releases/download/v${APKTOOL_VERSION}/apktool_${APKTOOL_VERSION}.jar"
JAR_PATH="${HOME}/.local/share/apktool/apktool.jar"
WRAPPER="${HOME}/.local/bin/apktool"

main() {
    if command_exists apktool; then
        log "apktool already installed at $(command -v apktool), skipping."
        return 0
    fi

    local TEMP_DIR
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf '$TEMP_DIR'" RETURN

    log "Installing apktool ${APKTOOL_VERSION}..."
    mkdir -p "$(dirname "$JAR_PATH")" "$(dirname "$WRAPPER")"
    download_and_verify "$JAR_URL" "$TEMP_DIR/apktool.jar"
    mv "$TEMP_DIR/apktool.jar" "$JAR_PATH"

    cat > "$WRAPPER" <<'EOF'
#!/bin/bash
exec java -jar "${HOME}/.local/share/apktool/apktool.jar" "$@"
EOF
    chmod +x "$WRAPPER"

    log "apktool ${APKTOOL_VERSION} installed."
}

main "$@"
