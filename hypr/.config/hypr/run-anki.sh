#!/usr/bin/env bash

# 1. Force Anki to use Wayland instead of XWayland
export ANKI_WAYLAND=1
export QT_QPA_PLATFORM="wayland;xcb"

# 2. Disable Qt's automatic scaling which conflicts with Hyprland
export QT_AUTO_SCREEN_SCALE_FACTOR=0

# 3. Force a consistent scale factor (1 = 100%, 2 = 200%)
# If it's too small, he can change this to 1.25 or 1.5
export QT_SCALE_FACTOR=1

# 4. Launch Anki and pass all script arguments to it
exec anki "$@"


