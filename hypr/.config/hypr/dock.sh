#!/bin/bash
# Automatically generated dock script to safely upgrade resolutions
omarchy-hyprland-monitor-internal off
sleep 1
wlr-randr --output DP-3 --mode 3440x1440 || true
wlr-randr --output DP-5 --mode 3440x1440 || true
wlr-randr --output HDMI-A-1 --mode 3440x1440 || true
