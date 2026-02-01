#!/bin/bash
# test_runner.sh - Builds test images and runs the new mise-based setup inside them.

set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DOCKERFILE="Dockerfile.test"
DISTROS=("ubuntu-test" "kali-test" "parrot-test")

# --- Colors for logging ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_step() { echo -e "\n${BLUE}>>> $1${NC}"; }
log_success() { echo -e "${GREEN}✔ $1${NC}"; }

# --- Main Logic ---
main() {
    # Ensure Docker is running
    if ! docker info >/dev/null 2>&1; then
        echo "Error: Docker does not seem to be running. Please start Docker and try again." >&2
        exit 1
    fi

    for distro in "${DISTROS[@]}"; do
        log_step "Building test image for $distro..."
        docker build --target "$distro" -t "dotfiles-tester-$distro" -f "$DOCKERFILE" .
        log_success "Image for $distro built."

        log_step "Making scripts executable..."
        chmod +x system_setup.sh user_setup.sh

        log_step "Running setup workflow in $distro container..."
        # We run the container with the local dotfiles mounted as a volume.
        # The command now reflects the new two-step process:
        # 1. Run setup.sh with sudo for system-wide changes.
        # 2. Run mise as the regular user to install tools.
        docker run --rm \
               -v "$DOTFILES_DIR:/home/tester/dotfiles" \
               "dotfiles-tester-$distro" \
               /bin/bash -c "sudo /home/tester/dotfiles/system_setup.sh all"
        
        log_success "Setup workflow completed successfully in $distro."
    done

    log_step "All tests completed successfully!"
}

main "$@"
