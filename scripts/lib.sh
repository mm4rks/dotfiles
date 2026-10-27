#!/bin/bash
# scripts/lib.sh: Common utility functions for setup scripts.

# --- Logging ---
# Usage: log "my message"
log() { echo -e "\033[0;32m[INFO]\033[0m $1"; }

# Usage: warn "my message"
warn() { echo -e "\033[0;33m[WARN]\033[0m $1" >&2; }

# Usage: error "my message"
error() { echo -e "\033[0;31m[ERROR]\033[0m $1" >&2; exit 1; }


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

# Checks if the current user is in a specific group (exact name match).
# Usage: user_in_group docker
user_in_group() {
    [[ " $(id -nG) " == *" $1 "* ]]
}

# Prefix for user-level installs. Guest mode points this into the repo's
# gitignored .guest/ directory so nothing is written to $HOME.
# shellcheck disable=SC2034  # used by the scripts that source this file
LOCAL_PREFIX="${DOTFILES_PREFIX:-${HOME}/.local}"

# --- Python ---
# Some pwn tools need a newer Python than e.g. Ubuntu 22.04 ships (3.10):
# Certipy is pinned to 3.12, NetExec needs >= 3.11. ensure_python312 fetches
# a pinned standalone build (python-build-standalone) to hand to pipx.
PYTHON312_DIR="${LOCAL_PREFIX}/opt/python3.12"
PYTHON312_BIN="${PYTHON312_DIR}/bin/python3"
PYTHON312_URL="https://github.com/astral-sh/python-build-standalone/releases/download/20260825/cpython-3.12.14%2B20260825-x86_64-unknown-linux-gnu-install_only.tar.gz"
PYTHON312_SHA256="cbdd2f0cf02f941bc5c81e546f377275e322733abffe805ac29d2b7e8a58f7e3"

ensure_python312() {
    if [ -x "$PYTHON312_BIN" ]; then
        return 0
    fi

    log "Fetching standalone Python 3.12..."
    local archive
    archive="$(mktemp)"
    local extract_dir
    extract_dir="$(mktemp -d)"
    trap "rm -rf '$extract_dir' '$archive'" RETURN

    download_and_verify "$PYTHON312_URL" "$archive" "$PYTHON312_SHA256"
    tar -xzf "$archive" -C "$extract_dir"
    mkdir -p "$(dirname "$PYTHON312_DIR")"
    rm -rf "$PYTHON312_DIR"
    mv "${extract_dir}/python" "$PYTHON312_DIR"
}

# pipx install on the standalone Python 3.12. Its sysconfig names clang as the
# compiler, so source builds (e.g. netifaces) use the system gcc instead.
# Usage: pipx_install_py312 <pipx install args...>
pipx_install_py312() {
    ensure_python312
    CC="${CC:-gcc}" CXX="${CXX:-g++}" pipx install --python "$PYTHON312_BIN" "$@"
}
