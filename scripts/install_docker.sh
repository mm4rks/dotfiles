#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

install_docker_official() {
    if command_exists docker; then
        log "Docker is already installed."
        return 0
    fi
    log "Installing Docker (Official Repo)..."

    . /etc/os-release
    local DOCKER_OS_ID="$ID"
    local DOCKER_CODENAME="${VERSION_CODENAME:-}"

    if [[ "${PRETTY_NAME}" == *"Parrot"* || "$ID" == "parrot" || "$ID" == "kali" ]]; then
        warn "Docker does not provide a repo for '${PRETTY_NAME}'. Using the upstream Debian 'bookworm' repo instead."
        DOCKER_OS_ID="debian"
        DOCKER_CODENAME="bookworm"
    elif [ -z "$DOCKER_CODENAME" ]; then
        warn "Could not detect VERSION_CODENAME. Falling back to 'bookworm' for Docker repo."
        DOCKER_CODENAME="bookworm"
    fi

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL "https://download.docker.com/linux/${DOCKER_OS_ID}/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DOCKER_OS_ID $DOCKER_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    if ! apt-get update -qq; then
        warn "Docker repo metadata refresh failed. Falling back to distro docker packages."
        rm -f /etc/apt/sources.list.d/docker.list
        apt-get update -qq
        if ! apt-get install -y -qq docker.io docker-compose-plugin; then
            warn "docker-compose-plugin unavailable. Installing docker.io only."
            apt-get install -y -qq docker.io
        fi
        # This script is designed to be run with sudo, which sets SUDO_USER.
# If running as root without sudo (like in a Docker build), SUDO_USER will be empty.
if [ -n "${SUDO_USER:-}" ]; then
    usermod -aG docker "$SUDO_USER"
fi
        return 0
    fi

    if ! apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
        warn "Official Docker packages are unavailable for this distro snapshot. Falling back to distro docker packages."
        rm -f /etc/apt/sources.list.d/docker.list
        apt-get update -qq
        if ! apt-get install -y -qq docker.io docker-compose-plugin; then
            warn "docker-compose-plugin unavailable. Installing docker.io only."
            apt-get install -y -qq docker.io
        fi
    fi

    # This script is designed to be run with sudo, which sets SUDO_USER.
# If running as root without sudo (like in a Docker build), SUDO_USER will be empty.
if [ -n "${SUDO_USER:-}" ]; then
    usermod -aG docker "$SUDO_USER"
fi
}

install_docker_official
