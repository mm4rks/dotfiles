#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

# Installs pinned versions of the terminal tools that used to be managed by
# mise. Each tool is a single self-contained binary (or small tarball)
# downloaded from its GitHub releases page and verified against a pinned
# sha256 checksum, then linked into $LOCAL_PREFIX/bin (~/.local/bin, or the
# guest sandbox). A tool is (re)installed unless the copy in $LOCAL_PREFIX/bin
# already reports the pinned version, so a version bump upgrades in place and
# an unrelated distro binary elsewhere on PATH never masks the pin.

INSTALL_DIR="${LOCAL_PREFIX}/bin"
OPT_DIR="${LOCAL_PREFIX}/opt"

NEOVIM_VERSION="0.12.5"
NEOVIM_URL="https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/nvim-linux-x86_64.tar.gz"
NEOVIM_SHA256="bce0f56eda1f1b1db6eee8f4133d7a38813ea07933837dd1777411ca384c6875"

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

# Installs a whole extracted tree (e.g. neovim, node) under OPT_DIR/<name>
# (no root required) and symlinks its bin/* entries into INSTALL_DIR.
install_tree_from_tar() {
    local archive="$1" opt_name="$2"
    local opt_dir="${OPT_DIR}/${opt_name}"
    local extract_dir
    extract_dir="$(mktemp -d)"
    trap "rm -rf '$extract_dir'" RETURN

    tar -xf "$archive" -C "$extract_dir"

    local extracted_dir
    extracted_dir="$(find "$extract_dir" -mindepth 1 -maxdepth 1 -type d | head -n1)"
    if [ -z "$extracted_dir" ]; then
        error "Could not find extracted directory for ${opt_name} in ${archive}."
    fi

    mkdir -p "$OPT_DIR"
    rm -rf "$opt_dir"
    mv "$extracted_dir" "$opt_dir"

    local bin
    for bin in "${opt_dir}"/bin/*; do
        if [ -f "$bin" ]; then
            ln -sf "$bin" "${INSTALL_DIR}/$(basename "$bin")"
        fi
    done
}

# True if INSTALL_DIR/<bin> exists and its --version output mentions <version>.
is_pinned_version() {
    local bin="$1" version="$2" output
    [ -x "${INSTALL_DIR}/${bin}" ] || return 1
    # Captured rather than piped into `grep -q`, which can SIGPIPE the binary
    # and fail the check under pipefail.
    output="$("${INSTALL_DIR}/${bin}" --version 2>/dev/null)" || return 1
    [[ "$output" == *"$version"* ]]
}

# Usage: install_tool <bin> <version> <url> <sha256> <kind> [opt_name]
#   kind: tar  - single binary inside a tarball
#         tree - whole tarball under OPT_DIR/<opt_name>, bin/* linked
#         raw  - the download is the binary itself
install_tool() {
    local bin="$1" version="$2" url="$3" sha256="$4" kind="$5" opt_name="${6:-$1}"

    if is_pinned_version "$bin" "$version"; then
        log "${bin} ${version} is already installed."
        return 0
    fi

    log "Installing ${bin} ${version}..."
    local archive
    archive="$(mktemp)"
    download_and_verify "$url" "$archive" "$sha256"
    case "$kind" in
        tar) install_binary_from_tar "$archive" "$bin" ;;
        tree) install_tree_from_tar "$archive" "$opt_name" ;;
        raw) install -m 0755 "$archive" "${INSTALL_DIR}/${bin}" ;;
        *) error "Unknown install kind: ${kind}" ;;
    esac
    rm -f "$archive"
}

install_terminal_tools() {
    if [ "$(uname -m)" != "x86_64" ]; then
        error "Pinned terminal tool binaries are x86_64 only (this machine: $(uname -m))."
    fi

    mkdir -p "$INSTALL_DIR"

    install_tool nvim       "$NEOVIM_VERSION"     "$NEOVIM_URL"     "$NEOVIM_SHA256"     tree nvim
    install_tool zoxide     "$ZOXIDE_VERSION"     "$ZOXIDE_URL"     "$ZOXIDE_SHA256"     tar
    install_tool fzf        "$FZF_VERSION"        "$FZF_URL"        "$FZF_SHA256"        tar
    install_tool rg         "$RIPGREP_VERSION"    "$RIPGREP_URL"    "$RIPGREP_SHA256"    tar
    install_tool bat        "$BAT_VERSION"        "$BAT_URL"        "$BAT_SHA256"        tar
    install_tool eza        "$EZA_VERSION"        "$EZA_URL"        "$EZA_SHA256"        tar
    install_tool delta      "$DELTA_VERSION"      "$DELTA_URL"      "$DELTA_SHA256"      tar
    install_tool fd         "$FD_VERSION"         "$FD_URL"         "$FD_SHA256"         tar
    install_tool shellcheck "$SHELLCHECK_VERSION" "$SHELLCHECK_URL" "$SHELLCHECK_SHA256" tar
    install_tool choose     "$CHOOSE_VERSION"     "$CHOOSE_URL"     "$CHOOSE_SHA256"     raw
    install_tool node       "$NODE_VERSION"       "$NODE_URL"       "$NODE_SHA256"       tree node

    log "Terminal tools installed to ${INSTALL_DIR} (and ${OPT_DIR} for neovim/node)."
}

main() {
    install_terminal_tools
}

main "$@"
