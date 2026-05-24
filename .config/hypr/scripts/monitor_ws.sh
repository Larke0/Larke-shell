#!/usr/bin/env bash

# ==============================================================================
# Script: Monitor-Relative Workspace Switcher (Hyprland 0.55 Lua Native Update)
# Description: Switches workspaces relative to the current monitor's range.
# ==============================================================================

# --- CONFIGURATION ---
CONFIG_FILE="$HOME/.config/hypr/scripts/workspaces.json"
DEFAULT_START=1
DEFAULT_END=10

# --- ARGUMENT VALIDATION ---
if [[ "$#" -ne 2 ]]; then
  echo "Error: Invalid arguments."
  echo "Usage: $0 [workspace|movetoworkspace] [index|delta]"
  echo "Example: $0 workspace +1"
  exit 1
fi

action="workspace"
if [[ "$1" == "movetoworkspace" ]]; then
  action="movetoworkspace"
fi

target_input="$2"

# --- STEP 1: IDENTIFY CONTEXT ---
current_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

read start_ws end_ws < <(jq -r --arg name "$current_monitor" '.[$name] | "\(.start) \(.end)"' "$CONFIG_FILE")

if [[ "$start_ws" == "null" || -z "$start_ws" ]]; then
  start_ws=$DEFAULT_START
  end_ws=$DEFAULT_END
fi

current_id=$(hyprctl activeworkspace -j | jq '.id')
range_size=$((end_ws - start_ws + 1))

# --- STEP 2: CALCULATE TARGET ---
if [[ "$target_input" == +* || "$target_input" == -* ]]; then
  current_offset=$((current_id - start_ws))
  delta=$target_input
  new_offset=$(((current_offset + delta) % range_size))

  if ((new_offset < 0)); then
    new_offset=$((new_offset + range_size))
  fi

  final_target=$((start_ws + new_offset))
else
  base_offset=$(((target_input - 1) % range_size))
  final_target=$((start_ws + base_offset))
fi

# --- STEP 2.5: LUA-COMPLIANT SPECIAL WORKSPACE HANDLING ---
special_workspace=$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .specialWorkspace.name')
if [[ "$special_workspace" != "" ]]; then
  clean_name=${special_workspace#special:}
  # Updated to call the native Lua toggle_special API method
  hyprctl dispatch "hl.dsp.workspace.toggle_special(\"$clean_name\")"
fi

# --- STEP 3: LUA-COMPLIANT EXECUTION ---
echo "Dispatching: $action to $final_target"

if [[ "$action" == "workspace" ]]; then
  # Focus workspace 0.55+ Lua syntax
  hyprctl dispatch "hl.dsp.focus({ workspace = $final_target })"
elif [[ "$action" == "movetoworkspace" ]]; then
  # Move active window to workspace 0.55+ Lua syntax
  hyprctl dispatch "hl.dsp.window.move({ workspace = $final_target })"
fi
