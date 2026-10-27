#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

SSHD_CONFIG="/etc/ssh/sshd_config"
START_MARKER="# >>> dotfiles ssh hardening >>>"
END_MARKER="# <<< dotfiles ssh hardening <<<"
HARDENING=(
    "PubkeyAuthentication yes"
    "PasswordAuthentication no"
    "KbdInteractiveAuthentication no"
    "PermitRootLogin no"
)

# Refuse to disable password logins unless the user can still get in by key.
ensure_authorized_keys() {
    # This run sets PermitRootLogin no, so root's own keys don't count.
    local target_user="${SUDO_USER:-}"
    if [ -z "$target_user" ] || [ "$target_user" = "root" ]; then
        error "Run this via sudo from the (non-root) user who will log in over SSH."
    fi
    local target_home
    target_home="$(getent passwd "$target_user" | cut -d: -f6)"

    if [ ! -s "${target_home}/.ssh/authorized_keys" ]; then
        error "No ${target_home}/.ssh/authorized_keys for ${target_user}. Add a public key first; disabling password authentication now would lock you out."
    fi
}

# Writes the hardened config to stdout. sshd uses the first value it reads for
# each keyword, so the managed block goes at the very top (before any Include
# or Match block), and every other occurrence of the managed keywords is
# dropped so a Match block cannot re-enable them.
render_config() {
    local keywords
    keywords="$(printf '%s\n' "${HARDENING[@]}" | awk '{print $1}' | paste -sd'|')"
    # ChallengeResponseAuthentication is the deprecated alias of KbdInteractiveAuthentication.
    keywords+="|ChallengeResponseAuthentication"

    echo "$START_MARKER"
    printf '%s\n' "${HARDENING[@]}"
    echo "$END_MARKER"
    sed -e "/^${START_MARKER}\$/,/^${END_MARKER}\$/d" "$SSHD_CONFIG" \
        | grep -viE "^[[:space:]]*(${keywords})[[:space:]]*[[:space:]=]" || true
}

harden_ssh() {
    ensure_authorized_keys

    log "Installing openssh-server..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq openssh-server

    log "Hardening SSH..."
    # Keep the distro's original config once; later runs never overwrite it.
    if [ ! -f "${SSHD_CONFIG}.orig" ]; then
        cp -p "$SSHD_CONFIG" "${SSHD_CONFIG}.orig"
    fi

    local candidate
    candidate="$(mktemp)"
    trap "rm -f '$candidate'" RETURN
    render_config > "$candidate"

    # Legacy drop-in from earlier versions of this script.
    rm -f /etc/ssh/sshd_config.d/99-hardening.conf

    mkdir -p /run/sshd
    if ! sshd -t -f "$candidate"; then
        error "Hardened SSH config failed validation; ${SSHD_CONFIG} was left unchanged."
    fi
    install -m 0644 "$candidate" "$SSHD_CONFIG"
    log "SSH configuration validated and installed."

    if command_exists systemctl; then
        systemctl enable ssh || warn "Failed to enable ssh service."
        systemctl restart ssh || warn "Failed to restart ssh service, might be running in a container."
    fi
}

main() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)."
    fi
    harden_ssh
}

main "$@"
