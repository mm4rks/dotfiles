-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- Laptop internal display
-- If booting with lid closed, disable immediately to prevent initial bandwidth crash with external displays
if os.execute("omarchy-hw-clamshell") == 0 then
  hl.monitor({ output = "eDP-1", disabled = true })
else
  hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 2 })
end

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
  hl.exec_cmd("omarchy-hyprland-monitor-internal off")
  -- The initial modeset likely failed due to Intel GPU bandwidth limits (trying to drive 4K + Ultrawide).
  -- Now that eDP-1 is off, force a modeset retry for the external monitors.
  hl.exec_cmd("sleep 1 && wlr-randr --output DP-3 --mode 3440x1440 && wlr-randr --output DP-5 --mode 3440x1440 && wlr-randr --output HDMI-A-1 --mode 3440x1440")
end)

hl.on("monitor.removed", function()
  -- NOTE: If the laptop screen stays black upon unplugging, Omarchy's system script
  -- might have been overwritten during an update. The script must ignore 'FALLBACK':
  -- sudo sed -i 's/\^(eDP|LVDS|DSI)-/\^(eDP|LVDS|DSI)-|^FALLBACK/' /usr/bin/omarchy-hyprland-monitor-external-active
  hl.exec_cmd("omarchy-hyprland-monitor-internal recover")
end)
