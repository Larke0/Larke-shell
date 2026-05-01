#!/usr/bin/env bash

# ==============================================================================
# Script: Monitor-Relative Workspace Switcher
# Description: Switches workspaces *relative to the current monitor's range*.
#              Supports both direct indexing (e.g., "Go to 2nd workspace on this monitor")
#              and relative wrapping (e.g., "Go to next/prev workspace on this monitor").
#
# Usage: ./monitor_ws.sh [action] [target]
#        [action]: "workspace" or "movetoworkspace"
#        [target]: Absolute index (1, 2) or Relative delta (+1, -1)
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

# --- ARGUMENT VALIDATION ---
if [[ "$#" -ne 2 ]]; then
    echo "Error: Invalid arguments."
    echo "Usage: $0 [workspace|movetoworkspace] [index|delta]"
    echo "Example: $0 workspace +1"
    exit 1
fi

# Parsing Action
# Default is switching focus. If "movetoworkspace" is passed, we move the window.
action="workspace"
if [[ "$1" == "movetoworkspace" ]]; then
    action="movetoworkspace"
fi

target_input="$2"

# --- STEP 1: IDENTIFY CONTEXT ---
# Get current monitor name
current_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

# Read Start/End config for this monitor
read start_ws end_ws < <(jq -r --arg name "$current_monitor" '.[$name] | "\(.start) \(.end)"' "$CONFIG_FILE")

# Fallback to defaults if monitor is not in JSON
if [[ "$start_ws" == "null" || -z "$start_ws" ]]; then
    start_ws=$DEFAULT_START
    end_ws=$DEFAULT_END
    # echo "Debug: Monitor not configured, using defaults ($start_ws-$end_ws)"
fi

# Get the ID of the actual workspace currently active
current_id=$(hyprctl activeworkspace -j | jq '.id')

# Calculate the total number of workspaces allocated to this monitor
range_size=$((end_ws - start_ws + 1))


# --- STEP 2: CALCULATE TARGET ---

if [[ "$target_input" == +* || "$target_input" == -* ]]; then
    # === RELATIVE MOVEMENT (Next/Prev) ===
    # Example: Input is "+1" or "-1"

    # 1. Normalize current ID to a 0-based index relative to the monitor
    # (e.g., if range starts at 11 and we are on 13, offset is 2)
    current_offset=$((current_id - start_ws))

    # 2. Apply the delta (add/subtract)
    delta=$target_input
    
    # 3. Use Modulo (%) to wrap around the range
    new_offset=$(((current_offset + delta) % range_size ))

    # 4. Handle Negative Wrapping
    # Bash modulo returns negative numbers for negative inputs (e.g., -1 % 10 = -1).
    # We want it to wrap to the end (e.g., 9).
    if (( new_offset < 0 )); then
        new_offset=$((new_offset + range_size))
    fi

    # 5. Convert back to Absolute Hyprland ID
    final_target=$((start_ws + new_offset))

else
    # === DIRECT INDEXING ===
    # Example: Input is "1" (meaning 1st workspace on this monitor)

    # Sanity Check: Clamp input to avoid going outside monitor bounds
    if (( target_input > range_size )); then target_input=$range_size; fi
    if (( target_input < 1 )); then target_input=1; fi
    
    # Convert local index (1-based) to Absolute ID
    # If Start is 11 and input is 1: 11 + 1 - 1 = 11.
    final_target=$((start_ws + target_input - 1))
fi


#Get the current special workspace
special_workspace=$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .specialWorkspace.name')
echo "$special_workspace"
if [[ "$special_workspace" != "" ]]; then
	# Remove "special:" from the start of the variable
	clean_name=${special_workspace#special:}
	
	echo "$clean_name"
	hyprctl dispatch togglespecialworkspace "$clean_name"

fi



# --- STEP 3: EXECUTION ---
echo "Dispatching: $action to $final_target"
hyprctl dispatch $action $final_target


