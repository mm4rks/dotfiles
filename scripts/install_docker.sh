#!/bin/bash
set -euo pipefail
REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)
source "${REPO_DIR}/scripts/lib.sh"

install_docker_official() {
    if command_exists docker; then
        log "Docker is already installed."
        return 0
    fi

    log "Installing Docker (Official Repo)..."

    # Ensure dependencies are present
    apt-get update -qq
    apt-get install -y -qq ca-certificates curl gnupg

    . /etc/os-release
    local DOCKER_OS_ID="$ID"
    local DOCKER_CODENAME="${VERSION_CODENAME:-}"

    # Handle Kali and Parrot as Debian Bookworm
    if [[ "${PRETTY_NAME:-}" == *"Parrot"* || "$ID" == "parrot" || "$ID" == "kali" ]]; then
        warn "Docker does not provide an official repo for '${PRETTY_NAME:-$ID}'. Using Debian 'bookworm' as fallback."
        DOCKER_OS_ID="debian"
        DOCKER_CODENAME="bookworm"
    elif [ -z "$DOCKER_CODENAME" ]; then
        warn "Could not detect VERSION_CODENAME. Defaulting to 'bookworm' for Docker repo."
        DOCKER_OS_ID="debian"
        DOCKER_CODENAME="bookworm"
    fi

    install -m 0755 -d /etc/apt/keyrings
    if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
        curl -fsSL "https://download.docker.com/linux/${DOCKER_OS_ID}/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg
    fi

    if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DOCKER_OS_ID $DOCKER_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    fi

    if ! apt-get update -qq; then
        warn "Docker repo metadata refresh failed. Falling back to distro packages."
        rm -f /etc/apt/sources.list.d/docker.list
        apt-get update -qq
        apt-get install -y -qq docker.io docker-compose-plugin || apt-get install -y -qq docker.io
    else
        apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    fi

    # Add user to docker group if running under sudo
    if [ -n "${SUDO_USER:-}" ]; then
        log "Adding user ${SUDO_USER} to the docker group..."
        usermod -aG docker "$SUDO_USER"
    fi
}

main() {
    if [[ $EUID -ne 0 ]]; then
       error "This script must be run as root (use sudo)."
    fi
    install_docker_official
}

main "$@"
