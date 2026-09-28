#!/bin/bash

# Highlight the focused AeroSpace workspace and hide empty ones.
# $1: workspace name, $FOCUSED_WORKSPACE: passed by `sketchybar --trigger`

export PATH="/opt/homebrew/bin:$PATH"

FOCUSED_WORKSPACE="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
  sketchybar --set "$NAME" drawing=on background.drawing=on
elif [ "$(aerospace list-windows --workspace "$1" --count)" -gt 0 ]; then
  sketchybar --set "$NAME" drawing=on background.drawing=off
else
  sketchybar --set "$NAME" drawing=off
fi
