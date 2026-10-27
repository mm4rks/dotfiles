#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

APKTOOL_VERSION="3.0.2"
JAR_URL="https://github.com/iBotPeaches/Apktool/releases/download/v${APKTOOL_VERSION}/apktool_${APKTOOL_VERSION}.jar"
JAR_SHA256="eee4669a704a14e0623407e6701b0b91887e61e1e4049cb7a82833e14ae8b5fd"
JAR_PATH="${LOCAL_PREFIX}/share/apktool/apktool.jar"
VERSION_FILE="${LOCAL_PREFIX}/share/apktool/.dotfiles-version"
WRAPPER="${LOCAL_PREFIX}/bin/apktool"

main() {
    if [ -x "$WRAPPER" ] && [ "$(cat "$VERSION_FILE" 2>/dev/null)" = "$APKTOOL_VERSION" ]; then
        log "apktool ${APKTOOL_VERSION} is already installed, skipping."
        return 0
    fi

    local TEMP_DIR
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf '$TEMP_DIR'" RETURN

    log "Installing apktool ${APKTOOL_VERSION}..."
    mkdir -p "$(dirname "$JAR_PATH")" "$(dirname "$WRAPPER")"
    download_and_verify "$JAR_URL" "$TEMP_DIR/apktool.jar" "$JAR_SHA256"
    mv "$TEMP_DIR/apktool.jar" "$JAR_PATH"

    cat > "$WRAPPER" <<WRAPPER_EOF
#!/bin/bash
exec java -jar "${JAR_PATH}" "\$@"
WRAPPER_EOF
    chmod +x "$WRAPPER"
    echo "$APKTOOL_VERSION" > "$VERSION_FILE"

    log "apktool ${APKTOOL_VERSION} installed."
}

main "$@"
