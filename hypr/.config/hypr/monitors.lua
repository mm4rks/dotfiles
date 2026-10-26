-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = 2

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- Laptop internal display (safe default)
-- NOTE: Do NOT set `disabled = true` here statically at boot! If eDP-1 is
-- statically disabled before Hyprland's first atomic commit, Aquamarine never
-- modesets CRTC 59 (`eDP-1`), leaving the kernel `i915drmfb` Plymouth splash
-- holding CRTC 59's bandwidth while freezing the laptop screen on the boot image.
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- External ultrawide displays (Docked profiles)
hl.monitor({ output = "DP-3", mode = "preferred", position = "auto", scale = 1 })
hl.monitor({ output = "DP-5", mode = "preferred", position = "auto", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "auto", scale = 1 })

-- Fallback rule for any other hotplugged external display
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Dock/undock synchronization:
-- Disables eDP-1 via Omarchy's toggle after initial modeset and upgrades the
-- external display to 3440x1440 once eDP-1's CRTC bandwidth is released.
local sync_cmd = os.getenv("HOME") .. "/.config/hypr/dock-sync.sh"
o.exec_on_start(sync_cmd)
hl.on("monitor.added", function()
  hl.exec_cmd(sync_cmd)
end)
hl.on("monitor.removed", function()
  hl.exec_cmd(sync_cmd)
end)
