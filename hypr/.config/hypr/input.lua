-- Personal input overrides.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input

hl.config({
  input = {
    kb_layout = "eu",
    kb_options = "",
    kb_variant = "",
    follow_mouse = 1,

    repeat_rate = 40,
    repeat_delay = 600,

    numlock_by_default = true,

    touchpad = {
      natural_scroll = true,
      scroll_factor = 0.4,
    },
  },

  cursor = {
    no_warps = false,
  },
})

-- App-specific touchpad scroll speeds.
o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })
o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })
