#!/usr/bin/env bash

# ==============================================================================
# Script: Close Active Special Workspace
# Description: Detects if a special workspace is open on the focused monitor
#              and toggles it off using the Hyprland 0.55+ Lua API.
# ==============================================================================

# 1. Identify the special workspace on the currently focused monitor
special_workspace=$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .specialWorkspace.name')

# 2. Check if a special workspace is actually open
if [[ "$special_workspace" != "" && "$special_workspace" != "null" ]]; then

  # Strip the "special:" prefix from the raw name
  clean_name=${special_workspace#special:}

  echo "Closing special workspace: $clean_name"

  # 3. Dispatch the Lua toggle command to minimize it
  hyprctl dispatch "hl.dsp.workspace.toggle_special(\"$clean_name\")"

else
  echo "No special workspace is currently open on the focused monitor."
fi
