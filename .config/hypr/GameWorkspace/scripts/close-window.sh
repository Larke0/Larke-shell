#!/bin/bash

# Dependency check: Ensure jq is installed
if ! command -v jq &> /dev/null; then
    notify-send "Error" "jq is missing. Install it with: sudo pacman -S jq"
    exit 1
fi

# Get details about the currently active window
WINDOW_INFO=$(hyprctl activewindow -j)

# Extract Class, PID, and Address
CLASS=$(echo "$WINDOW_INFO" | jq -r ".class")
PID=$(echo "$WINDOW_INFO" | jq -r ".pid")
ADDRESS=$(echo "$WINDOW_INFO" | jq -r ".address")

# Define keywords that trigger a FORCE KILL (kill -9)
# Matches gamescope, steam apps, windows exes, and wine processes
TARGETS=("gamescope")

FORCE_KILL=0

# Check if the active window class contains any of the target keywords
for target in "${TARGETS[@]}"; do
    if [[ "$CLASS" == *"$target"* ]]; then
        FORCE_KILL=1
        break
    fi
done

if [[ "$FORCE_KILL" -eq 1 ]]; then
    # METHOD 1: Kill gamescope
    kill -9 "$PID"
    #notify-send -u low -t 2000 "Force Killed" "$CLASS"
else
    # METHOD 2: The Polite Option (for regular apps)
    hyprctl dispatch closewindow address:"$ADDRESS"
fi
