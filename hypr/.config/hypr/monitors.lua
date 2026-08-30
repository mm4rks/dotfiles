-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- Laptop internal display (safe default)
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 2 })

-- External ultrawide displays (Docked profiles)
-- Using 'preferred' allows Omarchy's native 'modeless' recovery daemon to detect
-- missing EDIDs on cold boot (width=0). Hardcoding the resolution blinds the daemon.
hl.monitor({ output = "DP-3", mode = "preferred", position = "auto", scale = 1 })
hl.monitor({ output = "DP-5", mode = "preferred", position = "auto", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "auto", scale = 1 })

-- Fallback rule for any other hotplugged external display
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Automatically disable internal monitor when any external monitor is added,
-- mimicking kanshi's behavior but using Omarchy's native toggles so it doesn't fight clamshell.
hl.on("monitor.added", function()
  hl.exec_cmd("omarchy-hyprland-monitor-internal off")
end)

hl.on("monitor.removed", function()
  -- Let the clamshell watcher re-enable the screen dynamically
end)
