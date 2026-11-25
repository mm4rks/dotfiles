-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = 2

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- Laptop internal display
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- External ultrawide displays
hl.monitor({ output = "DP-3", mode = "preferred", position = "auto", scale = 1 })
hl.monitor({ output = "DP-5", mode = "preferred", position = "auto", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "auto", scale = 1 })

-- Fallback rule for any other hotplugged external display
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
