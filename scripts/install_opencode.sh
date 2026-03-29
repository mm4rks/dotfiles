#!/bin/bash
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)
source "${REPO_DIR}/scripts/lib.sh"

main() {
    local CACHE_FLAG=""
    if [[ "${1:-}" == "--update" ]] || [[ "${1:-}" == "-u" ]]; then
        log "Forcing a fresh update of opencode and plugins (no-cache)..."
        CACHE_FLAG="--no-cache"
    fi

    log "Building opencode-sandbox Docker image..."
    
    if ! command -v docker &>/dev/null; then
        error "Docker is not installed. Cannot build opencode-sandbox."
    fi

    if docker build $CACHE_FLAG -t opencode-sandbox:latest -f "${REPO_DIR}/docker/opencode/Dockerfile" "${REPO_DIR}/docker/opencode"; then
        log "Successfully built opencode-sandbox:latest"
    else
        error "Failed to build opencode-sandbox Docker image."
    fi
}

main "$@"
