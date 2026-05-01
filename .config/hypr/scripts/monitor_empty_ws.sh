#!/usr/bin/env bash

# ==============================================================================
# Script: Monitor Empty Workspace Switcher
# Description: Finds the first empty workspace within a monitor's specific range
#              and switches to it (or moves the active window to it).
# Dependencies: hyprland, jq, grep, notify-send
# ==============================================================================

# --- CONFIGURATION ---
CONFIG_FILE="$HOME/.config/hypr/scripts/workspaces.json"
DEFAULT_START=1
DEFAULT_END=10

# JSON Structure Example for workspaces.json:
# {
#   "DP-1": { "start": 1, "end": 10 },
#   "HDMI-A-1": { "start": 11, "end": 20 }
# }
# ---------------------

# --- ARGUMENT PARSING ---
# Default behavior: Switch focus to the new workspace
action="workspace"
max_windows=0

# If "move" argument is provided: Move active window -> Switch to new workspace
# We allow max_windows=1 because if we are moving a window, the current workspace
# effectively becomes empty after the move (if it was the only window there).
if [[ "$1" == "move" ]]; then
    action="movetoworkspace"
    max_windows=1
fi

# --- STEP 1: IDENTIFY CONTEXT ---
# Get the name of the currently focused monitor
current_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

# Extract the Start/End workspace IDs for this monitor from the JSON config
read start_ws end_ws < <(jq -r --arg name "$current_monitor" '.[$name] | "\(.start) \(.end)"' "$CONFIG_FILE")

# Fallback: If monitor is not found in JSON (returns null/empty), apply defaults
if [[ "$start_ws" == "null" || -z "$start_ws" ]]; then
    start_ws=$DEFAULT_START
    end_ws=$DEFAULT_END
    # Optional: Log error to stderr or notification
    # echo "Warning: Monitor '$current_monitor' not found in json, using defaults." >&2
fi

# --- STEP 2: FIND TARGET WORKSPACE ---
# Get list of all currently occupied workspace IDs
occupied=$(hyprctl workspaces -j | jq '.[] | .id')

target=-1
index=$start_ws

# Loop through the monitor's range to find the first ID *not* in the occupied list
while [[ $index -le $end_ws ]]; do
    if ! echo "$occupied" | grep -q "^$index$"; then
        target=$index
        break
    fi
    ((index++))
done

# Error handling: If no empty slots are found in the range
if [[ "$target" -le -1 ]]; then
    notify-send "Hyprland" "No empty workspaces available" --icon=hyprland
    exit 0
fi

# --- STEP 3: VALIDATION & EXECUTION ---
# Get the ID of the workspace we are currently standing on
current_id=$(hyprctl activeworkspace -j | jq '.id')

# Debug logging (optional)
echo "target: $target | current_id: $current_id"

# Logic: If the target empty workspace is numerically lower than or equal to current,
# just go there. This handles "backfilling" gaps (e.g., you closed a window on WS 1 
# while you are on WS 3, so it fills WS 1).
if [[ "$target" -le "$current_id" ]]; then
   hyprctl dispatch $action $target
   exit 0
fi

# Logic: Check if we are already on an "empty" workspace to prevent redundancy.
# If we are just switching (max_windows=0) and current has 0 windows: Stay here.
# If we are moving (max_windows=1) and current has 1 window: Stay here (we are moving the only window).
windows=$(hyprctl activeworkspace -j | jq '.windows')

if [[ "$windows" -le "$max_windows" ]]; then
    echo "Current workspace is already empty/available. No action taken."
    exit 0
fi 

# Final execution: Dispatch the Hyprland command
hyprctl dispatch $action $target
