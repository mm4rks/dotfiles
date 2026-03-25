#!/bin/bash
# scripts/lib.sh: Common utility functions for setup scripts.

# --- Logging ---
# Usage: log "my message"
log() { echo -e "\033[0;32m[INFO]\033[0m $1"; }

# Usage: warn "my message"
warn() { echo -e "\033[0;33m[WARN]\033[0m $1"; }

# Usage: error "my message"
error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; exit 1; }


# --- File Operations ---
# Downloads a file and optionally verifies its SHA256 checksum.
# Usage: download_and_verify <url> <output_path> [sha256sum]
download_and_verify() {
    local url="$1"
    local output_path="$2"
    local expected_sum="${3:-}"
    local temp_path="${output_path}.tmp"

    log "Downloading from ${url}..."
    if ! curl --retry 3 --fail --location -o "${temp_path}" "$url"; then
        rm -f "${temp_path}"
        error "Failed to download from ${url}"
    fi

    if [ -n "$expected_sum" ]; then
        log "Verifying checksum for $(basename "$output_path")..."
        local actual_sum
        actual_sum=$(sha256sum "${temp_path}" | awk '{print $1}')
        if [ "$actual_sum" != "$expected_sum" ]; then
            rm -f "${temp_path}"
            error "Checksum mismatch for ${output_path}.\n  Expected: ${expected_sum}\n  Actual:   ${actual_sum}"
        fi
        log "Checksum valid."
    fi

    mv "${temp_path}" "${output_path}"
}

# --- System Checks ---
# Checks if a command is available.
# Usage: command_exists docker
command_exists() {
    command -v "$1" &>/dev/null
}
