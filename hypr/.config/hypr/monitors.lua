-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- Laptop internal display (safe default)
-- We explicitly want eDP-1 enabled at boot so that the initial DRM modeset
-- forces external monitors to fallback to a lower resolution, avoiding a GPU crash.
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 2 })

-- External ultrawide displays (Docked profiles)
-- Using 'highres' allows a lower resolution fallback to pass initial GPU bandwidth
-- checks alongside the 4K internal screen, preventing a permanent DRM modeset crash.
hl.monitor({ output = "DP-3", mode = "highres", position = "auto", scale = 1 })
hl.monitor({ output = "DP-5", mode = "highres", position = "auto", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "highres", position = "auto", scale = 1 })

-- Fallback rule for any other hotplugged external display
hl.monitor({ output = "", mode = "highres", position = "auto", scale = 1 })

-- Automatically disable internal monitor when any external monitor is added,
-- mimicking kanshi's behavior but using Omarchy's native toggles so it doesn't fight clamshell.
hl.on("monitor.added", function()
  hl.exec_cmd("~/.config/hypr/dock.sh &")
end)

hl.on("monitor.removed", function()
  -- NOTE: If the laptop screen stays black upon unplugging, Omarchy's system script
  -- might have been overwritten during an update. The script must ignore 'FALLBACK':
  -- sudo sed -i 's/\^(eDP|LVDS|DSI)-/\^(eDP|LVDS|DSI)-|^FALLBACK/' /usr/bin/omarchy-hyprland-monitor-external-active
  hl.exec_cmd("omarchy-hyprland-monitor-internal recover")
end)
