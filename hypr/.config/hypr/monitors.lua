-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- Laptop internal display
-- If booting with lid closed, disable immediately to prevent initial bandwidth crash with external displays
local clamshell_status = os.execute("/usr/bin/omarchy-hw-clamshell >/dev/null 2>&1")
if clamshell_status == 0 or clamshell_status == true then
  hl.monitor({ output = "eDP-1", disabled = true })
else
  hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 2 })
end

-- External ultrawide displays (Docked profiles)
-- Using 'preferred' instead of 'highres' to avoid 100Hz modeset failures that cause a black screen on boot.
hl.monitor({ output = "DP-3", mode = "preferred", position = "auto", scale = 1 })
hl.monitor({ output = "DP-5", mode = "preferred", position = "auto", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "auto", scale = 1 })

-- Fallback rule for any other hotplugged external display
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

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
