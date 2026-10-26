#!/bin/bash
set -euo pipefail

run_sync() {
    local lock_file="${XDG_RUNTIME_DIR:-/tmp}/hypr-dock-sync.lock"
    exec 9>"$lock_file"
    # Wait up to 5 seconds if another event is in progress so a quick
    # unplug/replug is never dropped while the previous event is sleeping.
    flock -w 5 9 || return 0

    if omarchy-hw-external-monitors; then
        # 1. Disable internal monitor via Omarchy's official toggle (writes
        #    internal-monitor-disable.lua and runs hyprctl reload, releasing eDP-1's CRTC).
        omarchy-hyprland-monitor-internal off >/dev/null 2>&1 || true

        # 2. Wait for eDP-1's CRTC to release, then upgrade any active external
        #    monitor that fell back to a lower resolution (e.g. 2560x1080) during
        #    the initial dual-CRTC modeset.
        #    NOTE: `hyprctl eval 'hl.monitor(...)'` is a no-op if the resolved mode
        #    matches the rule already in monitors.lua; `wlr-randr` directly triggers
        #    a wlr_output_management modeset commit to 3440x1440.
        sleep 1
        local mon
        while IFS= read -r mon; do
            if [ -n "$mon" ] && [[ "$mon" =~ ^[A-Za-z0-9._-]+$ ]]; then
                wlr-randr --output "$mon" --mode 3440x1440 >/dev/null 2>&1 || true
            fi
        done < <(hyprctl monitors -j | jq -r '.[] | select(.name | test("^(eDP|LVDS|DSI)-") | not) | select(.disabled == false) | .name')
    else
        # No external monitor connected: recover internal display if disabled.
        omarchy-hyprland-monitor-internal recover >/dev/null 2>&1 || true
    fi
}

main() {
    run_sync "$@"
}
main "$@"
