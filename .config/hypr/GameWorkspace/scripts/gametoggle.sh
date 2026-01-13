#!/bin/bash

# === CONFIGURATION ===
# Set your Main Monitor where the game should always appear
MAIN_MONITOR="$1"

# Set to true to force game into windowed mode on hide, and restore fullscreen on show.
# Set to false to leave the window state exactly as it is (no resizing/flickering).
ENABLE_FULLSCREEN_RESTORE=false


# === FILES TO STORE STATES ===
GAME_CACHE_FILE="/tmp/hypr_fullscreen_game"
FOCUS_CACHE_FILE="/tmp/hypr_last_focus"

# 1. Get info about the CURRENTLY FOCUSED monitor
monitor_info=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true)')
current_monitor_name=$(echo "$monitor_info" | jq -r '.name')
active_special=$(echo "$monitor_info" | jq -r '.specialWorkspace.name')

# Check if we are currently INSIDE the game workspace
if [[ "$active_special" == "special:games" ]]; then
    # ==========================================================
    # CASE: CLOSING (Game -> Desktop)
    # ==========================================================

    # 1. Handle Game Fullscreen Logic (ONLY IF ENABLED)
    if [ "$ENABLE_FULLSCREEN_RESTORE" = true ]; then
        window_info=$(hyprctl activewindow -j)
        is_fullscreen=$(echo "$window_info" | jq -r '.fullscreen')
        window_addr=$(echo "$window_info" | jq -r '.address')

        if [[ "$is_fullscreen" == "1" || "$is_fullscreen" == "2" ]]; then
            # SAVE ADDRESS AND THE SPECIFIC STATE (1 or 2)
            echo "$window_addr $is_fullscreen" > "$GAME_CACHE_FILE"

            # Turn off the specific mode correctly so it restores cleanly later
            if [[ "$is_fullscreen" == "1" ]]; then
                hyprctl dispatch fullscreen 1 # Toggle off Maximize
            else
                hyprctl dispatch fullscreen 0 # Toggle off True Fullscreen
            fi
            sleep 0.1
        else
            rm -f "$GAME_CACHE_FILE"
        fi
    else
        # If disabled, ensure we don't leave stale cache files
        rm -f "$GAME_CACHE_FILE"
    fi

    # 2. Toggle Workspace (Hide it)
    hyprctl dispatch togglespecialworkspace games

    sleep 0.05

    # 3. Restore Previous Focus (Monitor -> Window -> Mouse Position)
    if [[ -f "$FOCUS_CACHE_FILE" ]]; then
        read last_window saved_monitor < "$FOCUS_CACHE_FILE"

        # Safety Check: Don't focus if the window is inside the game workspace
        target_ws=$(hyprctl clients -j | jq -r ".[] | select(.address == \"$last_window\") | .workspace.name")

        if [[ "$target_ws" == "special:games" ]]; then
            hyprctl dispatch focusmonitor "$current_monitor_name"
        else
            if [[ -n "$saved_monitor" ]]; then
                hyprctl dispatch focusmonitor "$saved_monitor"
            fi

            sleep 0.05

            hyprctl dispatch focuswindow address:$last_window

            # Warp mouse logic
            window_geo=$(hyprctl clients -j | jq -r ".[] | select(.address == \"$last_window\") | \"\(.at[0]) \(.at[1]) \(.size[0]) \(.size[1])\"")

            if [[ -n "$window_geo" ]]; then
                read x y w h <<< "$window_geo"
                center_x=$((x + w / 2))
                center_y=$((y + h / 2))
                hyprctl dispatch movecursor absolute $center_x $center_y
            fi
        fi
        rm -f "$FOCUS_CACHE_FILE"
    else
        hyprctl dispatch focusmonitor "$current_monitor_name"
    fi

else
    # ==========================================================
    # CASE: OPENING (Desktop -> Game)
    # ==========================================================

    # --- CHECK IF GAMES WORKSPACE IS EMPTY ---
    game_count=$(hyprctl clients -j | jq '[.[] | select(.workspace.name == "special:games")] | length')
    if [[ "$game_count" -eq 0 ]]; then
        notify-send -t 2000 "Game Mode" "No games running!"
        exit 0
    fi

    # --- HIT-BOX CHECK ---
    window_info=$(hyprctl activewindow -j)
    current_addr=$(echo "$window_info" | jq -r '.address')

    if [[ "$current_addr" != "null" && -n "$current_addr" ]]; then
        cursor_pos=$(hyprctl cursorpos -j)
        cx=$(echo "$cursor_pos" | jq '.x')
        cy=$(echo "$cursor_pos" | jq '.y')
        wx=$(echo "$window_info" | jq '.at[0]')
        wy=$(echo "$window_info" | jq '.at[1]')
        ww=$(echo "$window_info" | jq '.size[0]')
        wh=$(echo "$window_info" | jq '.size[1]')

        # Only save if mouse is actually INSIDE the window
        if (( cx >= wx && cx <= wx + ww && cy >= wy && cy <= wy + wh )); then
            echo "$current_addr $current_monitor_name" > "$FOCUS_CACHE_FILE"
        else
            rm -f "$FOCUS_CACHE_FILE"
        fi
    else
        rm -f "$FOCUS_CACHE_FILE"
    fi

    #If main monitor was passed, do the check:
    if [ -n "$MAIN_MONITOR" ]; then
        # --- MAIN MONITOR CHECK ---
        # Check if the game is ALREADY visible on the Main Monitor
        main_monitor_special=$(hyprctl monitors -j | jq -r ".[] | select(.name == \"$MAIN_MONITOR\") | .specialWorkspace.name")

        # Force focus to Main Monitor
        hyprctl dispatch focusmonitor "$MAIN_MONITOR"
        sleep 0.05

        # Only toggle if it's NOT already there
        if [[ "$main_monitor_special" != "special:games" ]]; then
            hyprctl dispatch togglespecialworkspace games
        fi
    else
        # If no monitor arg, just toggle where we are or where it was
        hyprctl dispatch togglespecialworkspace games
    fi

    # Increased sleep for Minecraft/Java apps to render
    sleep 0.0

    # 3. Focus the Game
    game_address=$(hyprctl clients -j | jq -r '.[] | select(.workspace.name == "special:games") | .address' | head -n 1)

    # --- RESTORE LOGIC (ONLY IF ENABLED) ---
    if [ "$ENABLE_FULLSCREEN_RESTORE" = true ] && [[ -f "$GAME_CACHE_FILE" ]]; then
        # READ ADDRESS AND STATE
        read saved_addr saved_state < "$GAME_CACHE_FILE"

        if [[ "$game_address" == "$saved_addr" ]]; then
            hyprctl dispatch focuswindow address:$game_address

            # --- INTELLIGENT FULLSCREEN RESTORE ---
            current_fs_state=$(hyprctl clients -j | jq -r ".[] | select(.address == \"$game_address\") | .fullscreen")

            # Only attempt restore if currently windowed (0) to avoid loops or conflicts
            if [[ "$current_fs_state" == "0" ]]; then
                sleep 0.1
                if [[ "$saved_state" == "1" ]]; then
                    # Restore Maximize
                    hyprctl dispatch fullscreen 1
                elif [[ "$saved_state" == "2" ]]; then
                    # Restore True Fullscreen
                    hyprctl dispatch fullscreen 0
                fi
            fi
            # --------------------------------------
        fi
        rm -f "$GAME_CACHE_FILE"
    elif [[ -n "$game_address" ]]; then
        # Standard focus if restore is disabled or no cache exists
        hyprctl dispatch focuswindow address:$game_address
    fi
fi
