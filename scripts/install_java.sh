#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

install_java() {
    local REQUIRED_VERSION="21"
    log "Checking for Java ${REQUIRED_VERSION}..."

    local java_version=""
    if command_exists java; then
        # Capture major version (e.g., "21" from "21.0.4")
        java_version=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}' | cut -d. -f1)
        # Fallback for different java -version formats
        if [ -z "$java_version" ]; then
            java_version=$(java -version 2>&1 | head -n 1 | awk '{print $3}' | tr -d '"' | cut -d. -f1)
        fi
    fi

    if [ "$java_version" != "$REQUIRED_VERSION" ]; then
        log "Installing OpenJDK ${REQUIRED_VERSION}..."
        apt-get update -qq && apt-get install -y -qq "openjdk-${REQUIRED_VERSION}-jdk"
    else
        log "Java ${REQUIRED_VERSION} is already installed."
    fi
}

main() {
    if [[ $EUID -ne 0 ]]; then
       error "This script must be run as root (use sudo)."
    fi
    install_java
}

main "$@"
