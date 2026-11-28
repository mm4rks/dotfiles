#!/bin/bash
set -euo pipefail

wait_for_external_active() {
    local i
    for i in $(seq 1 20); do
        if omarchy-hyprland-monitor-external-active; then
            return 0
        fi
        sleep 0.25
    done
    return 1
}

wait_for_internal_disabled() {
    local i
    for i in $(seq 1 16); do
        if hyprctl monitors all -j 2>/dev/null | jq -e '.[] | select(.name | test("^(eDP|LVDS|DSI)-")) | .disabled == true' >/dev/null 2>&1; then
            return 0
        fi
        sleep 0.25
    done
    return 1
}

upgrade_external_modes() {
    local attempt mon upgraded
    for attempt in 1 2 3; do
        upgraded=0
        while IFS= read -r mon; do
            if [ -n "$mon" ] && [[ "$mon" =~ ^[A-Za-z0-9._-]+$ ]]; then
                wlr-randr --output "$mon" --mode 3440x1440 >/dev/null 2>&1 || true
                upgraded=1
            fi
        done < <(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.name | test("^(eDP|LVDS|DSI)-") | not) | select(.disabled == false) | select(.availableModes | any(startswith("3440x1440@"))) | select(.width != 3440) | .name')

        if [ "$upgraded" -eq 0 ]; then
            return 0
        fi
        sleep 1
    done
}

run_sync() {
    local lock_file="${XDG_RUNTIME_DIR:-/tmp}/hypr-dock-sync.lock"
    exec 9>"$lock_file"
    # Wait up to 5 seconds if another event is in progress so a quick
    # unplug/replug is never dropped while the previous event is sleeping.
    flock -w 5 9 || return 0

    if omarchy-hw-external-monitors; then
        # Wait briefly at boot for Hyprland to register the external connector
        # before disabling eDP-1 (omarchy-hyprland-monitor-internal off refuses
        # to run if no external monitor is active yet).
        wait_for_external_active || return 0

        # 1. Disable internal monitor via Omarchy's official toggle (writes
        #    internal-monitor-disable.lua and runs hyprctl reload, releasing eDP-1's CRTC).
        omarchy-hyprland-monitor-internal off >/dev/null 2>&1 || true

        # 2. Wait for eDP-1's CRTC to release, then upgrade any active external
        #    monitor that fell back to a lower resolution (e.g. 2560x1080) during
        #    the initial dual-CRTC modeset.
        #    NOTE: `hyprctl eval 'hl.monitor(...)'` is a no-op if the resolved mode
        #    matches the rule already in monitors.lua; `wlr-randr` directly triggers
        #    a wlr_output_management modeset commit to 3440x1440.
        wait_for_internal_disabled || true
        sleep 0.5
        upgrade_external_modes
    else
        # No external monitor connected: recover internal display if disabled.
        omarchy-hyprland-monitor-internal recover >/dev/null 2>&1 || true
    fi
}

main() {
    run_sync "$@"
}
main "$@"
