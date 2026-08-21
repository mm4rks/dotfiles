-- Extra autostart processes.
o.launch_on_start("alacritty --class main-terminal -e tmux new-session -A -s main")

-- DisplayPort link negotiation on cold boot/reboot while docked takes 1-2s,
-- and sometimes fails to fire a udev hotplug event. Poll sysfs manually.
o.launch_on_start([[
  bash -c '
    for i in {1..15}; do
      if omarchy-hw-external-monitors; then
        # Monitor detected in sysfs. Wait a second for it to settle,
        # then force a reload so Hyprland enumerates it.
        sleep 1
        hyprctl reload
        exit 0
      fi
      sleep 1
    done
  ' >/dev/null 2>&1
]])
