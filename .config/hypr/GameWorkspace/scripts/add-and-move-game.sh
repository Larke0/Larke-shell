#!/bin/bash

# --- CONFIGURATION ---
JSON_FILE="$HOME/.config/hypr/GameWorkspace/scripts/game-list.json"
UPDATE_SCRIPT="$HOME/.config/hypr/GameWorkspace/scripts/update-gamerules.sh"
GAMETOGGLE_SCRIPT="$HOME/.config/hypr/GameWorkspace/scripts/gametoggle.sh"

# Ensure JSON file exists with an empty array if not present
if [ ! -f "$JSON_FILE" ]; then
    echo "[]" > "$JSON_FILE"
fi

# --- STEP 1: GET ACTIVE WINDOW INFO ---
ACTIVE_WINDOW_INFO=$(hyprctl -j activewindow)

# We capture INITIAL Class, Title AND current Class
ACTIVE_CLASS=$(echo "$ACTIVE_WINDOW_INFO" | jq -r '.initialClass')
ACTIVE_TITLE=$(echo "$ACTIVE_WINDOW_INFO" | jq -r '.initialTitle')
ACTIVE_CURRENT_CLASS=$(echo "$ACTIVE_WINDOW_INFO" | jq -r '.class')
ACTIVE_WORKSPACE=$(echo "$ACTIVE_WINDOW_INFO" | jq -r '.workspace.name')

# --- STEP 2: VALIDATE ---
if [ -z "$ACTIVE_CLASS" ] || [ -z "$ACTIVE_TITLE" ] || [ "$ACTIVE_CLASS" == "null" ]; then
    echo "Initial Class or Title is empty/null. Aborting."
    exit 1
fi

# --- STEP 3: CHECK IF WINDOW IS ALREADY IN THE GAME WORKSPACE ---
JSON_TMP_FILE="$JSON_FILE.tmp"
JQ_FILTER=""

if [ "$ACTIVE_WORKSPACE" == "special:games" ]; then
    # --- STEP 4a: REMOVE FROM LIST ---
    echo "Window is in 'special:games'. Removing it..."

    # FIND THE WORKSPACE BELOW
    # We get the currently focused monitor, then look at its 'activeWorkspace' ID.
    # Even if a special workspace is open, activeWorkspace refers to the regular one behind it.
    TARGET_WORKSPACE=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .activeWorkspace.id')

    # Fallback sanity check: if for some reason it's empty, default to 1
    if [ -z "$TARGET_WORKSPACE" ] || [ "$TARGET_WORKSPACE" == "null" ]; then
        TARGET_WORKSPACE=1
    fi

    # Move back to the detected workspace
    hyprctl dispatch movetoworkspacesilent "$TARGET_WORKSPACE"


    # Delete the object matching INITIAL attributes
    JQ_FILTER="del(.[] | select(.initial_class == \"$ACTIVE_CLASS\" and .initial_title == \"$ACTIVE_TITLE\"))"

else
    # --- STEP 4b: ADD TO LIST ---
    echo "Window is not in 'special:games'. Adding it..."

    # Move to special workspace
    hyprctl dispatch movetoworkspacesilent special:games

    if [ -x "$GAMETOGGLE_SCRIPT" ]; then
        "$GAMETOGGLE_SCRIPT"
    else
        echo "Update script not found or not executable."
    fi


    # Add the new object with 'initial_class', 'initial_title', AND 'app_class' keys
    JQ_FILTER="if any(.[]; .initial_class == \"$ACTIVE_CLASS\" and .initial_title == \"$ACTIVE_TITLE\") then . else . + [{\"initial_class\": \"$ACTIVE_CLASS\", \"initial_title\": \"$ACTIVE_TITLE\", \"app_class\": \"$ACTIVE_CURRENT_CLASS\"}] end"
fi

# --- STEP 5: APPLY THE JSON CHANGE ---
jq "$JQ_FILTER" "$JSON_FILE" > "$JSON_TMP_FILE"

if [ $? -eq 0 ]; then
    mv "$JSON_TMP_FILE" "$JSON_FILE"
    echo "Processed: [$ACTIVE_CLASS] $ACTIVE_TITLE ($ACTIVE_CURRENT_CLASS)"
else
    echo "Error: Failed to update $JSON_FILE." >&2
    rm -f "$JSON_TMP_FILE"
    exit 1
fi

# --- STEP 6: RUN THE UPDATE SCRIPT ---
if [ -x "$UPDATE_SCRIPT" ]; then
    "$UPDATE_SCRIPT"
else
    echo "Update script not found or not executable."
fi

exit 0
