-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- --- Workspace & Window Rules ---
o.window("^(main-terminal)$", { workspace = "1" })
o.window("^(org\\.mozilla\\.Thunderbird)$", { workspace = "2 silent" })
o.window("^(anki)$", { workspace = "3", size = "60% 60%" })
o.window("^(spotify)$", { workspace = "5 silent" })
o.window("^(discord)$", { workspace = "5 silent" })
o.window("(?i)virtualbox", { float = true })
o.window("^(steam_app_.*)$", { render_unfocused = true })
o.window("(?i)wine", { render_unfocused = true })
o.window("(?i)exefile.exe", { render_unfocused = true })

-- --- Performance & Rendering Tweaks ---
hl.config({
  misc = {
    render_unfocused_fps = 60,
  },
})

-- --- GPU & DRM Environment Variables ---
hl.env("NVD_BACKEND", "direct")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
