-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- Application bindings
hl.unbind("SUPER + ALT + RETURN")
o.bind("SUPER + ALT + RETURN", "Tmux", 'uwsm-app -- xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)" tmux new')

hl.unbind("SUPER + RETURN")
o.bind("SUPER + RETURN", "Terminal", 'uwsm-app -- xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)"')

hl.unbind("SUPER + SHIFT + RETURN")
o.bind("SUPER + SHIFT + RETURN", "Browser", "omarchy-launch-browser")

o.bind("SUPER + Q", "Main Terminal", "omarchy-launch-or-focus 'main-terminal' \"alacritty --class 'main-terminal' -e tmux new-session -A -s main\"")

hl.unbind("SUPER + SHIFT + F")
o.bind("SUPER + SHIFT + F", "File manager", "uwsm-app -- nautilus --new-window")

hl.unbind("SUPER + ALT + SHIFT + F")
o.bind("SUPER + ALT + SHIFT + F", "File manager (cwd)", 'uwsm-app -- nautilus --new-window "$(omarchy-cmd-terminal-cwd)"')

hl.unbind("SUPER + B")
o.bind("SUPER + B", "Firefox", "omarchy-launch-or-focus 'firefox'")

hl.unbind("SUPER + SHIFT + ALT + B")
o.bind("SUPER + SHIFT + ALT + B", "Browser (private)", "$browser --private")

hl.unbind("SUPER + SHIFT + M")
o.bind("SUPER + SHIFT + M", "Music", "omarchy-launch-or-focus spotify")

hl.unbind("SUPER + SHIFT + ALT + M")
o.bind("SUPER + SHIFT + ALT + M", "Music TUI", "omarchy-launch-or-focus-tui cliamp")

hl.unbind("SUPER + SHIFT + N")
o.bind("SUPER + SHIFT + N", "Editor", "omarchy-launch-editor")

hl.unbind("SUPER + SHIFT + D")
o.bind("SUPER + SHIFT + D", "Docker", "omarchy-launch-tui lazydocker")

o.bind("SUPER + D", "Dictation", "voxtype record toggle")

hl.unbind("SUPER + SHIFT + S")
o.bind("SUPER + SHIFT + S", "Signal", 'omarchy-launch-or-focus signal "uwsm-app -- signal-desktop"')

hl.unbind("SUPER + SHIFT + SLASH")
o.bind("SUPER + SHIFT + SLASH", "Passwords", "omarchy-launch-or-focus keepassxc")

hl.unbind("SUPER + SHIFT + C")
o.bind("SUPER + SHIFT + C", "Anki", os.getenv("HOME") .. "/.config/hypr/run-anki.sh")

-- Web Apps
hl.unbind("SUPER + SHIFT + A")
o.bind("SUPER + SHIFT + A", "Gemini", 'omarchy-launch-webapp "https://gemini.google.com/app"')

o.bind("SUPER + A", "Log Note", "vnote-toggle")

hl.unbind("SUPER + SHIFT + G")
o.bind("SUPER + SHIFT + G", "GitHub", 'omarchy-launch-webapp "https://github.com/mm4rks/dotfiles"')

hl.unbind("SUPER + SHIFT + Y")
o.bind("SUPER + SHIFT + Y", "YouTube", 'omarchy-launch-webapp "https://youtube.com/"')

-- Overwrite existing bindings
hl.unbind("SUPER + O")
o.bind("SUPER + O", "Obsidian", 'omarchy-launch-or-focus "^obsidian$" "uwsm-app -- obsidian"')

hl.unbind("SUPER + E")
o.bind("SUPER + E", "Apps menu", "omarchy-menu toggle apps")
o.bind("SUPER + R", "Omarchy menu", "omarchy-menu")

-- Focus navigation (Vim-style)
hl.bind("ALT + H", hl.dsp.focus({ direction = "l" }), { description = "Focus left" })
hl.bind("ALT + J", hl.dsp.focus({ direction = "d" }), { description = "Focus down" })
hl.bind("ALT + K", hl.dsp.focus({ direction = "u" }), { description = "Focus up" })
hl.bind("ALT + L", hl.dsp.focus({ direction = "r" }), { description = "Focus right" })

-- Move window (Vim-style)
hl.bind("ALT + SHIFT + H", hl.dsp.window.move({ direction = "l" }), { description = "Move window left" })
hl.bind("ALT + SHIFT + J", hl.dsp.window.move({ direction = "d" }), { description = "Move window down" })
hl.bind("ALT + SHIFT + K", hl.dsp.window.move({ direction = "u" }), { description = "Move window up" })
hl.bind("ALT + SHIFT + L", hl.dsp.window.move({ direction = "r" }), { description = "Move window right" })

-- Mumble Push-to-Talk (Side Mouse Button / BTN_SIDE / mouse:275)
hl.bind("mouse:275", hl.dsp.exec_cmd("mumble rpc starttalking"), { mouse = true, description = "Mumble start talking" })
hl.bind("mouse:275", hl.dsp.exec_cmd("mumble rpc stoptalking"), { mouse = true, release = true, description = "Mumble stop talking" })

-- Send F12 to Discord Canary via side mouse button (275)
hl.bind("mouse:275", hl.dsp.exec_cmd("hyprctl dispatch sendshortcut ,,F12,class:^discord-canary$"), { mouse = true, description = "Discord PTT press" })
hl.bind("mouse:275", hl.dsp.exec_cmd("hyprctl dispatch sendshortcut ,,F12,class:^discord-canary$"), { mouse = true, release = true, description = "Discord PTT release" })
