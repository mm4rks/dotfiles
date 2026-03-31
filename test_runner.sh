#!/bin/bash
# test_runner.sh - Builds test images. If the build succeeds, all scripts passed.

set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
DOCKERFILE="Dockerfile.test"
DISTROS=("ubuntu-test" "kali-test" "kali-guest-test")

# --- Colors for logging ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_step() { echo -e "\n${BLUE}>>> $1${NC}"; }
log_success() { echo -e "${GREEN}✔ $1${NC}"; }

# --- Main Logic ---
main() {
    # If arguments are provided, use them as the list of distros to test
    if [ $# -gt 0 ]; then
        DISTROS=("$@")
    fi

    # Ensure Docker is running
    if ! docker info >/dev/null 2>&1; then
        echo "Error: Docker does not seem to be running. Please start Docker and try again." >&2
        exit 1
    fi

    for distro in "${DISTROS[@]}"; do
        log_step "Building and verifying test image for $distro..."
        # If the build succeeds, it means all scripts installed and verified correctly.
        docker build --target "$distro" -t "dotfiles-tester-$distro" -f "$DOCKERFILE" .
        log_success "Tests passed for $distro!"
    done

    log_step "All tests completed successfully!"
}

main "$@"
