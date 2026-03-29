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

    # Check for Docker and install it if missing
    if ! command_exists docker; then
        warn "Docker is not installed. Attempting to install Docker..."
        if ! sudo "${REPO_DIR}/scripts/install_docker.sh"; then
            error "Failed to install Docker automatically. Please install it manually."
        fi
        # Re-check if install was successful
        if ! command_exists docker; then
            error "Docker installation finished but 'docker' command is still not found in PATH."
        fi
    fi

    # Check if the user is in the docker group
    if ! user_in_group docker; then
        warn "Current user $(whoami) is not in the 'docker' group. You may need to restart your session after being added."
        # Attempt to add user to docker group if not already there
        sudo usermod -aG docker "$(whoami)"
        log "Added $(whoami) to the docker group. Please re-login for changes to take effect."
    fi

    log "Building opencode-sandbox Docker image..."
    if docker build $CACHE_FLAG -t opencode-sandbox:latest -f "${REPO_DIR}/docker/opencode/Dockerfile" "${REPO_DIR}/docker/opencode"; then
        log "Successfully built opencode-sandbox:latest"
    else
        error "Failed to build opencode-sandbox Docker image."
    fi
}

main "$@"
