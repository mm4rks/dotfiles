-- Change the default Omarchy look'n'feel.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/

hl.config({
  general = {
    -- No window gaps/margins
    gaps_in = 0,
    gaps_out = 0,
    border_size = 1,
  },

  layout = {
    -- Avoid overly wide single-window layouts on wide screens
    single_window_aspect_ratio = { 1.9, 1 },
  },
})
