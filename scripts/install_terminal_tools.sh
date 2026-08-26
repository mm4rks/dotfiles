#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

# Installs pinned versions of the terminal tools that used to be managed by
# mise. Each tool is a single self-contained binary (or small tarball)
# downloaded from its GitHub releases page and verified against a pinned
# sha256 checksum, then linked into ~/.local/bin.

INSTALL_DIR="${HOME}/.local/bin"

NEOVIM_VERSION="0.12.5"
NEOVIM_URL="https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/nvim-linux-x86_64.tar.gz"
NEOVIM_SHA256="bce0f56eda1f1b1db6eee8f4133d7a38813ea07933837dd1777411ca384c6875"

STARSHIP_VERSION="1.26.0"
STARSHIP_URL="https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-x86_64-unknown-linux-gnu.tar.gz"
STARSHIP_SHA256="321f0dd7af8340a5f2e6a8fec6538a04f617486f9ec70d878f91c09cd8deef22"

ZOXIDE_VERSION="0.10.0"
ZOXIDE_URL="https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION}-x86_64-unknown-linux-musl.tar.gz"
ZOXIDE_SHA256="2d93385b99f3e82cf2701609a1bffcad863fbeb75aa3fe7eb6be4d29be68b1ae"

FZF_VERSION="0.74.3"
FZF_URL="https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz"
FZF_SHA256="3501a595e4b5c40a6b047340a0e8f805c46fd4e61ef95ef8a136ba8c61cf6f22"

RIPGREP_VERSION="15.2.0"
RIPGREP_URL="https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl.tar.gz"
RIPGREP_SHA256="33e15bcf1624b25cdd2a55813a47a2f95dbe126268203e76aa6a585d1e7b149c"

BAT_VERSION="0.26.1"
BAT_URL="https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-v${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz"
BAT_SHA256="0dcd8ac79732c0d5b136f11f4ee00e581440e16a44eab5b3105b611bbf2cf191"

EZA_VERSION="0.23.5"
EZA_URL="https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_x86_64-unknown-linux-gnu.tar.gz"
EZA_SHA256="35c70c5c43c29108075e58b893234c67ef585f0b53a7eaf8e9e7d4eec9f339b4"

DELTA_VERSION="0.19.2"
DELTA_URL="https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
DELTA_SHA256="8e695c5f586a8c53d6c3b01be0b4a422ed218bfed2a56191caebe373a1c18ab2"

FD_VERSION="10.5.0"
FD_URL="https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz"
FD_SHA256="761c72dc8e120d85b22292063be8a796e2eeb20eb3e4f38b8fa2343ccf3514a7"

SHELLCHECK_VERSION="0.11.0"
SHELLCHECK_URL="https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.xz"
SHELLCHECK_SHA256="8c3be12b05d5c177a04c29e3c78ce89ac86f1595681cab149b65b97c4e227198"

CHOOSE_VERSION="1.3.7"
CHOOSE_URL="https://github.com/theryangeary/choose/releases/download/v${CHOOSE_VERSION}/choose-x86_64-unknown-linux-musl"
CHOOSE_SHA256="f9958b15b9c5e2ed21162dcd21e514b51a03efc8dcbf730546c3dbef8a2eba2a"

NODE_VERSION="24.19.0"
NODE_URL="https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz"
NODE_SHA256="14b342e71204f811bde6153be8e04b62aef63c236fef92b55f9c83154b409647"

# Extracts a single binary named $2 out of a tar archive at $1 (searched
# recursively) and installs it into INSTALL_DIR as $3 (defaults to $2).
install_binary_from_tar() {
    local archive="$1" bin_name="$2" install_name="${3:-$2}"
    local extract_dir
    extract_dir="$(mktemp -d)"
    trap "rm -rf '$extract_dir'" RETURN

    tar -xf "$archive" -C "$extract_dir"

    local found
    found="$(find "$extract_dir" -type f -name "$bin_name" | head -n1)"
    if [ -z "$found" ]; then
        error "Could not find '${bin_name}' inside ${archive}."
    fi

    install -m 0755 "$found" "${INSTALL_DIR}/${install_name}"
}

# Installs a whole extracted tree (e.g. neovim, node) under
# ~/.local/opt/<name> (no root required) and symlinks its bin/* entries into
# INSTALL_DIR.
install_tree_from_tar() {
    local archive="$1" opt_name="$2"
    local opt_dir="${HOME}/.local/opt/${opt_name}"
    local extract_dir
    extract_dir="$(mktemp -d)"
    trap "rm -rf '$extract_dir'" RETURN

    tar -xf "$archive" -C "$extract_dir"

    local extracted_dir
    extracted_dir="$(find "$extract_dir" -mindepth 1 -maxdepth 1 -type d | head -n1)"
    if [ -z "$extracted_dir" ]; then
        error "Could not find extracted directory for ${opt_name} in ${archive}."
    fi

    mkdir -p "${HOME}/.local/opt"
    rm -rf "$opt_dir"
    mv "$extracted_dir" "$opt_dir"

    for bin in "${opt_dir}"/bin/*; do
        [ -f "$bin" ] && ln -sf "$bin" "${INSTALL_DIR}/$(basename "$bin")"
    done
}

install_neovim() {
    if command_exists nvim; then
        log "Neovim is already installed."
        return 0
    fi
    log "Installing Neovim ${NEOVIM_VERSION}..."
    local archive; archive="$(mktemp)"
    download_and_verify "$NEOVIM_URL" "$archive" "$NEOVIM_SHA256"
    install_tree_from_tar "$archive" "nvim"
    rm -f "$archive"
}

install_starship() {
    if command_exists starship; then
        log "Starship is already installed."
        return 0
    fi
    log "Installing Starship ${STARSHIP_VERSION}..."
    local archive; archive="$(mktemp)"
    download_and_verify "$STARSHIP_URL" "$archive" "$STARSHIP_SHA256"
    install_binary_from_tar "$archive" "starship"
    rm -f "$archive"
}

install_zoxide() {
    if command_exists zoxide; then
        log "zoxide is already installed."
        return 0
    fi
    log "Installing zoxide ${ZOXIDE_VERSION}..."
    local archive; archive="$(mktemp)"
    download_and_verify "$ZOXIDE_URL" "$archive" "$ZOXIDE_SHA256"
    install_binary_from_tar "$archive" "zoxide"
    rm -f "$archive"
}

install_fzf() {
    if command_exists fzf; then
        log "fzf is already installed."
        return 0
    fi
    log "Installing fzf ${FZF_VERSION}..."
    local archive; archive="$(mktemp)"
    download_and_verify "$FZF_URL" "$archive" "$FZF_SHA256"
    install_binary_from_tar "$archive" "fzf"
    rm -f "$archive"
}

install_ripgrep() {
    if command_exists rg; then
        log "ripgrep is already installed."
        return 0
    fi
    log "Installing ripgrep ${RIPGREP_VERSION}..."
    local archive; archive="$(mktemp)"
    download_and_verify "$RIPGREP_URL" "$archive" "$RIPGREP_SHA256"
    install_binary_from_tar "$archive" "rg"
    rm -f "$archive"
}

install_bat() {
    if command_exists bat; then
        log "bat is already installed."
        return 0
    fi
    log "Installing bat ${BAT_VERSION}..."
    local archive; archive="$(mktemp)"
    download_and_verify "$BAT_URL" "$archive" "$BAT_SHA256"
    install_binary_from_tar "$archive" "bat"
    rm -f "$archive"
}

install_eza() {
    if command_exists eza; then
        log "eza is already installed."
        return 0
    fi
    log "Installing eza ${EZA_VERSION}..."
    local archive; archive="$(mktemp)"
    download_and_verify "$EZA_URL" "$archive" "$EZA_SHA256"
    install_binary_from_tar "$archive" "eza"
    rm -f "$archive"
}

install_delta() {
    if command_exists delta; then
        log "delta is already installed."
        return 0
    fi
    log "Installing delta ${DELTA_VERSION}..."
    local archive; archive="$(mktemp)"
    download_and_verify "$DELTA_URL" "$archive" "$DELTA_SHA256"
    install_binary_from_tar "$archive" "delta"
    rm -f "$archive"
}

install_fd() {
    if command_exists fd; then
        log "fd is already installed."
        return 0
    fi
    log "Installing fd ${FD_VERSION}..."
    local archive; archive="$(mktemp)"
    download_and_verify "$FD_URL" "$archive" "$FD_SHA256"
    install_binary_from_tar "$archive" "fd"
    rm -f "$archive"
}

install_shellcheck() {
    if command_exists shellcheck; then
        log "shellcheck is already installed."
        return 0
    fi
    log "Installing shellcheck ${SHELLCHECK_VERSION}..."
    local archive; archive="$(mktemp)"
    download_and_verify "$SHELLCHECK_URL" "$archive" "$SHELLCHECK_SHA256"
    install_binary_from_tar "$archive" "shellcheck"
    rm -f "$archive"
}

install_choose() {
    if command_exists choose; then
        log "choose is already installed."
        return 0
    fi
    log "Installing choose ${CHOOSE_VERSION}..."
    local bin_path="${INSTALL_DIR}/choose"
    download_and_verify "$CHOOSE_URL" "$bin_path" "$CHOOSE_SHA256"
    chmod +x "$bin_path"
}

install_node() {
    if command_exists node; then
        log "node is already installed."
        return 0
    fi
    log "Installing node ${NODE_VERSION}..."
    local archive; archive="$(mktemp)"
    download_and_verify "$NODE_URL" "$archive" "$NODE_SHA256"
    install_tree_from_tar "$archive" "node"
    rm -f "$archive"
}

install_terminal_tools() {
    mkdir -p "$INSTALL_DIR"

    install_neovim
    install_starship
    install_zoxide
    install_fzf
    install_ripgrep
    install_bat
    install_eza
    install_delta
    install_fd
    install_shellcheck
    install_choose
    install_node

    log "Terminal tools installed to ${INSTALL_DIR} (and ${HOME}/.local/opt for neovim/node)."
}

install_terminal_tools
