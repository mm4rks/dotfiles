#!/bin/bash
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# shellcheck source=lib.sh
source "${REPO_DIR}/lib.sh"

DC_VERSION="10.0.4"
DC_URL="https://github.com/jeremylong/DependencyCheck/releases/download/v${DC_VERSION}/dependency-check-${DC_VERSION}-release.zip"
INSTALL_DIR="${HOME}/.local/share/dependency-check"
WRAPPER="${HOME}/.local/bin/dependency-check"

main() {
    if command_exists dependency-check; then
        log "dependency-check already installed at $(command -v dependency-check), skipping."
        return 0
    fi

    local TEMP_DIR
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf '$TEMP_DIR'" RETURN

    log "Installing OWASP dependency-check ${DC_VERSION}..."
    download_and_verify "$DC_URL" "$TEMP_DIR/dependency-check.zip"

    rm -rf "$INSTALL_DIR"
    mkdir -p "$(dirname "$INSTALL_DIR")" "$(dirname "$WRAPPER")"
    unzip -q "$TEMP_DIR/dependency-check.zip" -d "$(dirname "$INSTALL_DIR")"
    chmod +x "$INSTALL_DIR/bin/dependency-check.sh"

    cat > "$WRAPPER" <<EOF
#!/bin/bash
exec "${INSTALL_DIR}/bin/dependency-check.sh" "\$@"
EOF
    chmod +x "$WRAPPER"

    log "dependency-check ${DC_VERSION} installed."
}

main "$@"
