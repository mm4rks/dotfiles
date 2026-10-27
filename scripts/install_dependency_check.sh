#!/bin/bash
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# shellcheck source=lib.sh
source "${REPO_DIR}/lib.sh"

DC_VERSION="10.0.4"
DC_URL="https://github.com/jeremylong/DependencyCheck/releases/download/v${DC_VERSION}/dependency-check-${DC_VERSION}-release.zip"
# Matches the SHA-1 published for this zip on Maven Central
# (org.owasp:dependency-check-cli:10.0.4:release).
DC_SHA256="0ea8345571b90cf418142b3a7c918d244be2d5101c99260794e8da84d5ee7f33"
INSTALL_DIR="${LOCAL_PREFIX}/share/dependency-check"
VERSION_FILE="${INSTALL_DIR}/.dotfiles-version"
WRAPPER="${LOCAL_PREFIX}/bin/dependency-check"

main() {
    if [ -x "$WRAPPER" ] && [ "$(cat "$VERSION_FILE" 2>/dev/null)" = "$DC_VERSION" ]; then
        log "dependency-check ${DC_VERSION} is already installed, skipping."
        return 0
    fi

    local TEMP_DIR
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf '$TEMP_DIR'" RETURN

    log "Installing OWASP dependency-check ${DC_VERSION}..."
    download_and_verify "$DC_URL" "$TEMP_DIR/dependency-check.zip" "$DC_SHA256"

    rm -rf "$INSTALL_DIR"
    mkdir -p "$(dirname "$INSTALL_DIR")" "$(dirname "$WRAPPER")"
    unzip -q "$TEMP_DIR/dependency-check.zip" -d "$(dirname "$INSTALL_DIR")"
    chmod +x "$INSTALL_DIR/bin/dependency-check.sh"

    cat > "$WRAPPER" <<WRAPPER_EOF
#!/bin/bash
exec "${INSTALL_DIR}/bin/dependency-check.sh" "\$@"
WRAPPER_EOF
    chmod +x "$WRAPPER"
    echo "$DC_VERSION" > "$VERSION_FILE"

    log "dependency-check ${DC_VERSION} installed."
}

main "$@"
