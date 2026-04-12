#!/bin/bash
set -euo pipefail
REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)
source "${REPO_DIR}/scripts/lib.sh"

install_docker_official() {
    if command_exists docker; then
        log "Docker is already installed."
        return 0
    fi

    log "Installing Docker..."

    if [ -f /etc/arch-release ]; then
        log "Arch Linux detected. Using pacman..."
        pacman -S --noconfirm docker docker-compose
    else
        log "Debian/Ubuntu detected. Using apt-get..."
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
    fi

    # Start and enable Docker
    if command_exists systemctl; then
        systemctl enable --now docker || warn "Failed to enable/start docker service."
    fi

    # Add user to docker group if running under sudo
    if [ -n "${SUDO_USER:-}" ]; then
        log "Adding user ${SUDO_USER} to the docker group..."
        usermod -aG docker "$SUDO_USER"
    fi
}

install_nvidia_toolkit() {
    if command_exists nvidia-ctk; then
        log "NVIDIA Container Toolkit is already installed."
        generate_cdi_spec
        return 0
    fi

    log "Checking for NVIDIA GPU..."
    if ! grep -qi "nvidia" /proc/bus/pci/devices 2>/dev/null && ! (command -v lspci >/dev/null && lspci | grep -qi "nvidia"); then
        warn "No NVIDIA GPU detected. Skipping NVIDIA Container Toolkit installation."
        return 0
    fi

    log "Installing NVIDIA Container Toolkit..."
    
    if [ -f /etc/arch-release ]; then
        log "Arch Linux detected. Using pacman..."
        pacman -S --noconfirm nvidia-container-toolkit
    else
        # Official NVIDIA instructions for apt-based distros
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
          && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            tee /etc/apt/sources.list.d/nvidia-container-toolkit.list \
          && \
            apt-get update -qq && \
            apt-get install -y -qq nvidia-container-toolkit
    fi

    generate_cdi_spec

    log "Configuring Docker to use NVIDIA runtime..."
    nvidia-ctk runtime configure --runtime=docker
    if command_exists systemctl; then
        systemctl restart docker || warn "Failed to restart Docker. You may need to restart it manually."
    fi
    
    log "NVIDIA Container Toolkit installation and configuration complete."
}

generate_cdi_spec() {
    log "Generating NVIDIA CDI specification..."
    mkdir -p /etc/cdi
    if nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml; then
        log "CDI specification generated at /etc/cdi/nvidia.yaml"
    else
        warn "Failed to generate CDI specification."
    fi
}


install_nvidia_toolkit() {
    if command_exists nvidia-ctk; then
        log "NVIDIA Container Toolkit is already installed."
        return 0
    fi

    log "Checking for NVIDIA GPU..."
    if ! grep -qi "nvidia" /proc/bus/pci/devices 2>/dev/null && ! (command -v lspci >/dev/null && lspci | grep -qi "nvidia"); then
        warn "No NVIDIA GPU detected. Skipping NVIDIA Container Toolkit installation."
        return 0
    fi

    log "Installing NVIDIA Container Toolkit..."
    
    # Official NVIDIA instructions for apt-based distros
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        tee /etc/apt/sources.list.d/nvidia-container-toolkit.list \
      && \
        apt-get update -qq && \
        apt-get install -y -qq nvidia-container-toolkit

    log "Configuring Docker to use NVIDIA runtime..."
    nvidia-ctk runtime configure --runtime=docker
    systemctl restart docker || warn "Failed to restart Docker. You may need to restart it manually."
    
    log "NVIDIA Container Toolkit installation and configuration complete."
}

main() {
    if [[ $EUID -ne 0 ]]; then
       error "This script must be run as root (use sudo)."
    fi
    install_docker_official
    install_nvidia_toolkit
}

main "$@"
