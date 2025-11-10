#!/bin/sh

IDENTIFIER=$1
LAUNCH_CMD=$2
MATCH_BY=${3:-title} # Default to title

if hyprctl clients -j | jq -e ".[] | select(.$MATCH_BY | test(\"^$IDENTIFIER$\"; \"i\"))" > /dev/null; then
    hyprctl dispatch focuswindow "$MATCH_BY:^($IDENTIFIER)$"
else
    $LAUNCH_CMD &
fi