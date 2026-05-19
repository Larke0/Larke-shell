#!/usr/bin/env bash

# ==============================================================================
# Script: Monitor Empty Workspace Switcher (Hyprland 0.55+ Lua Update)
# Description: Finds the first empty workspace within a monitor's specific range
#              and switches to it (or moves the active window to it).
# ==============================================================================

# --- CONFIGURATION ---
CONFIG_FILE="$HOME/.config/hypr/scripts/workspaces.json"
DEFAULT_START=1
DEFAULT_END=10

# --- ARGUMENT PARSING ---
action="workspace"
max_windows=0

if [[ "$1" == "move" ]]; then
  action="movetoworkspace"
  max_windows=1
fi

# --- STEP 1: IDENTIFY CONTEXT ---
current_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

read start_ws end_ws < <(jq -r --arg name "$current_monitor" '.[$name] | "\(.start) \(.end)"' "$CONFIG_FILE")

if [[ "$start_ws" == "null" || -z "$start_ws" ]]; then
  start_ws=$DEFAULT_START
  end_ws=$DEFAULT_END
fi

# --- STEP 2: FIND TARGET WORKSPACE ---
occupied=$(hyprctl workspaces -j | jq '.[] | .id')

target=-1
index=$start_ws

while [[ $index -le $end_ws ]]; do
  if ! echo "$occupied" | grep -q "^$index$"; then
    target=$index
    break
  fi
  ((index++))
done

if [[ "$target" -le -1 ]]; then
  notify-send "Hyprland" "No empty workspaces available" --icon=hyprland
  exit 0
fi

# --- STEP 3: VALIDATION & LUA NATIVE EXECUTION ---
current_id=$(hyprctl activeworkspace -j | jq '.id')

echo "target: $target | current_id: $current_id"

# Logic: Backfilling Gaps Routing Handler
if [[ "$target" -le "$current_id" ]]; then
  if [[ "$action" == "workspace" ]]; then
    hyprctl dispatch "hl.dsp.focus({ workspace = $target })"
  elif [[ "$action" == "movetoworkspace" ]]; then
    hyprctl dispatch "hl.dsp.window.move({ workspace = $target })"
  fi
  exit 0
fi

# Logic: Current Space Redundancy Check
windows=$(hyprctl activeworkspace -j | jq '.windows')

if [[ "$windows" -le "$max_windows" ]]; then
  echo "Current workspace is already empty/available. No action taken."
  exit 0
fi

# Final execution: Dispatch the Hyprland Lua command
if [[ "$action" == "workspace" ]]; then
  hyprctl dispatch "hl.dsp.focus({ workspace = $target })"
elif [[ "$action" == "movetoworkspace" ]]; then
  hyprctl dispatch "hl.dsp.window.move({ workspace = $target })"
fi
