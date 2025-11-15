#!/bin/bash

# Force correct GPU order (NVIDIA first, Intel second)
export WLR_DRM_DEVICES=/dev/dri/card2:/dev/dri/card1
export AQ_DRM_DEVICES=/dev/dri/card2:/dev/dri/card1

# Debug line: Log all env variables to a file
# This helps us see if it worked.
env > /tmp/hypr_env_debug.log

# Launch Hyprland
exec Hyprland
