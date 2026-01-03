#!/bin/bash

# --- CONFIGURATION ---
TARGET_FILE="/home/larke/.config/hypr/custom/Wallpaper-Engine/wallpapers.json"
UPDATE_SCRIPT="/home/larke/.config/hypr/custom/Wallpaper-Engine/update-wallpaper.sh"
HYPR_SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

echo "Starting watcher... Updating wallpaper"
bash "$UPDATE_SCRIPT" &

echo "Listening for events (File, Monitor, Power, Gamemode)..."

(
    # 1. FILE MONITOR
    inotifywait -m -e close_write --format "Config_Saved" "$TARGET_FILE" &

    # 2. HYPRLAND MONITOR
    # FIX: Added '^' to strictly match events starting with "monitor"
    # This ignores window titles containing the word "monitor".
    socat -u UNIX-CONNECT:"$HYPR_SOCKET" - | grep --line-buffered "^monitor" &

    # 3. GAMEMODE
    dbus-monitor --session "interface='com.feralinteractive.GameMode'" 2> /dev/null \
    | grep --line-buffered -E "member=.*(RegisterGame|UnregisterGame)" &

    # 4. POWER PROFILES
    dbus-monitor --system "path='/net/hadess/PowerProfiles',interface='org.freedesktop.DBus.Properties'" 2> /dev/null \
    | grep --line-buffered "member=PropertiesChanged" &

) | {
    # INITIALIZE STATE TRACKING
    LAST_PROFILE=$(powerprofilesctl get 2>/dev/null || echo "unknown")

    # Initialize timestamp to 0
    LAST_GM_TIME=0

    echo "Initial Power Profile: $LAST_PROFILE"

    while read -r event_line; do

        echo "Event detected: $event_line"

        # Default: We assume we SHOULD update.
        DO_UPDATE=true
        # Default: Run update instantly
        DELAY=0

        # --- POWER PROFILE LOGIC ---
        if [[ "$event_line" == *"PropertiesChanged"* ]]; then
            CURRENT_PROFILE=$(powerprofilesctl get 2>/dev/null || echo "unknown")

            if [ "$CURRENT_PROFILE" == "$LAST_PROFILE" ]; then
                echo "  -> Power profile didn't change. Skipping."
                DO_UPDATE=false
            elif [ "$CURRENT_PROFILE" != "power-saver" ] && [ "$LAST_PROFILE" != "power-saver" ]; then
                echo "  -> Power change ignored ($LAST_PROFILE -> $CURRENT_PROFILE). Skipping."
                DO_UPDATE=false
            else
                echo "  -> Power Change ($LAST_PROFILE -> $CURRENT_PROFILE). Updating."
            fi
            LAST_PROFILE="$CURRENT_PROFILE"
        fi

        # --- GAMEMODE TIMING LOGIC ---
        # Check if this is a GameMode event
        if [[ "$event_line" == *"GameMode"* ]] || [[ "$event_line" == *"RegisterGame"* ]]; then

            # Get current time in nanoseconds
            CURRENT_TIME=$(date +%s%N)

            # Calculate difference (Current - Last)
            TIME_DIFF=$((CURRENT_TIME - LAST_GM_TIME))

            # 200000000 nanoseconds = 0.2 seconds
            if [ "$TIME_DIFF" -lt 200000000 ]; then
                echo "  -> GameMode spam detected (within 0.2s). Skipping."
                DO_UPDATE=false
            else
                # Valid event! Update the timestamp
                LAST_GM_TIME=$CURRENT_TIME
                # Force a delay to let GameMode status settle before checking
                DELAY=3
            fi
        fi

        # --- EXECUTE UPDATE ---
        if [ "$DO_UPDATE" = true ]; then
            # Run in a subshell with a delay (if any)
            (sleep $DELAY; bash "$UPDATE_SCRIPT") &
        fi

        # Tiny sleep just to be nice to the CPU
        sleep 0.1

    done
}
