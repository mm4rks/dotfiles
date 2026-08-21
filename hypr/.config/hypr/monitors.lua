-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

_G.update_monitors = function()
  local has_external = false
  local p = io.popen("omarchy-hw-external-monitors && echo yes || echo no")
  if p then
    local res = p:read("*l")
    p:close()
    if res == "yes" then
      has_external = true
    end
  end

  if has_external then
    -- External display connected: disable laptop screen to dedicate GPU bandwidth to external ultrawide
    hl.monitor({ output = "eDP-1", disabled = true })
    hl.monitor({ output = "DP-3", mode = "3440x1440@60", position = "0x0", scale = 1 })
    hl.monitor({ output = "DP-5", mode = "3440x1440@60", position = "0x0", scale = 1 })
    hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "0x0", scale = 1 })
    hl.monitor({ output = "", mode = "preferred", position = "0x0", scale = 1 })
    
    hl.timer(function()
      hl.dispatch(hl.dsp.dpms({ action = "off" }))
      hl.timer(function()
        hl.dispatch(hl.dsp.dpms({ action = "on" }))
      end, { timeout = 1000, type = "oneshot" })
    end, { timeout = 100, type = "oneshot" })
  else
    -- Standalone laptop: enable internal 4K retina display at origin 0x0 and unblank
    hl.monitor({ output = "eDP-1", mode = "3840x2160@60", position = "0x0", scale = 2 })
    
    hl.timer(function()
      hl.dispatch(hl.dsp.dpms({ action = "off" }))
      hl.timer(function()
        hl.dispatch(hl.dsp.dpms({ action = "on" }))
        hl.dispatch(hl.dsp.focus({ monitor = "eDP-1" }))
      end, { timeout = 1000, type = "oneshot" })
    end, { timeout = 100, type = "oneshot" })
  end
end

-- Run immediately on load / boot
update_monitors()

-- Native Hyprland Lua event listeners
hl.on("monitor.added", function()
  update_monitors()
end)

hl.on("monitor.removed", function()
  update_monitors()
end)

-- DisplayPort link negotiation on cold boot/reboot while docked takes 1-2s:
hl.on("hyprland.start", function()
  hl.exec_cmd([[
    bash -c '
      for i in {1..15}; do
        if omarchy-hw-external-monitors; then
          sleep 1
          hyprctl eval "_G.update_monitors()"
          exit 0
        fi
        sleep 1
      done
    ' >/dev/null 2>&1 &
  ]])
end)
