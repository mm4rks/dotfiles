#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

harden_ssh() {
    log "Installing openssh-server..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq openssh-server

    log "Hardening SSH..."
    local SSHD_CONFIG="/etc/ssh/sshd_config"
    cp "$SSHD_CONFIG" "$SSHD_CONFIG.bak"

    # Ensure PubkeyAuthentication is 'yes'
    sed -i -E 's/^[# \t]*(PubkeyAuthentication).*/PubkeyAuthentication yes/' "$SSHD_CONFIG"
    if ! grep -qE '^PubkeyAuthentication yes$' "$SSHD_CONFIG"; then
        echo "PubkeyAuthentication yes" >> "$SSHD_CONFIG"
    fi

    # Ensure PasswordAuthentication is 'no'
    sed -i -E 's/^[# \t]*(PasswordAuthentication).*/PasswordAuthentication no/' "$SSHD_CONFIG"
    if ! grep -qE '^PasswordAuthentication no$' "$SSHD_CONFIG"; then
        echo "PasswordAuthentication no" >> "$SSHD_CONFIG"
    fi

    # Ensure PermitRootLogin is 'no'
    sed -i -E 's/^[# \t]*(PermitRootLogin).*/PermitRootLogin no/' "$SSHD_CONFIG"
    if ! grep -qE '^PermitRootLogin no$' "$SSHD_CONFIG"; then
        echo "PermitRootLogin no" >> "$SSHD_CONFIG"
    fi

    # Ensure ChallengeResponseAuthentication is 'no'
    sed -i -E 's/^[# \t]*(ChallengeResponseAuthentication).*/ChallengeResponseAuthentication no/' "$SSHD_CONFIG"
    if ! grep -qE '^ChallengeResponseAuthentication no$' "$SSHD_CONFIG"; then
        echo "ChallengeResponseAuthentication no" >> "$SSHD_CONFIG"
    fi

    # Remove the sshd_config.d include if it exists, as we are managing directly
    sed -i -E '/^Include \/etc\/ssh\/sshd_config.d/d' "$SSHD_CONFIG"
    # Also remove the 99-hardening.conf file if it exists
    rm -f /etc/ssh/sshd_config.d/99-hardening.conf 2>/dev/null

    mkdir -p /run/sshd
    if sshd -t; then
        log "SSH configuration validated."
        systemctl enable ssh
        systemctl restart ssh || log "Failed to restart ssh service, might be running in a container."
    else
        error "SSH Config syntax check failed. Reverting changes..."
        mv "$SSHD_CONFIG.bak" "$SSHD_CONFIG"
        exit 1
    fi
}

harden_ssh
