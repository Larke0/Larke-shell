#!/bin/bash

# --- CONFIGURATION ---
CONFIG_DIR="/home/larke/.config/hypr/custom/Wallpaper-Engine"
WALLPAPER_JSON="$CONFIG_DIR/wallpapers.json"
CONFIG_FILE="$CONFIG_DIR/wallpaper-config.json"
CACHE_DIR="$HOME/.cache/wallpaper-engine-cache"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# --- DEPENDENCY CHECK ---
dependencies=(jq swaybg linux-wallpaperengine)
for cmd in "${dependencies[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: Required command '$cmd' is not installed."
        exit 1
    fi
done

# Check files
if [ ! -f "$CONFIG_FILE" ]; then echo "Error: $CONFIG_FILE not found!"; exit 1; fi
if [ ! -f "$WALLPAPER_JSON" ]; then echo "Error: $WALLPAPER_JSON not found!"; exit 1; fi

# --- 1. LOAD SETTINGS ---
VAL_DEFAULT=$(jq -r '.FPS.default' "$CONFIG_FILE")
VAL_GAME=$(jq -r '.FPS.gamemode' "$CONFIG_FILE")
VAL_POWER=$(jq -r '.FPS.powersave' "$CONFIG_FILE")

# Load the mask setting (defaults to true if missing)
ENABLE_MASK=$(jq -r 'if .transition_mask == null then true else .transition_mask end' "$CONFIG_FILE")
echo "DEBUG: Transition Mask is set to: '$ENABLE_MASK'"

TARGET_FPS=$VAL_DEFAULT

# Check Power Profile
if command -v powerprofilesctl > /dev/null && powerprofilesctl get | grep -q "power-saver"; then
    echo "Power Saver is on"
    TARGET_FPS=$VAL_POWER
fi

# Check if GameMode is on
if command -v gamemoded > /dev/null && gamemoded -s | grep -q "is active"; then
    echo "Gamemode is on"
    TARGET_FPS=$VAL_GAME
fi

echo "Selected FPS: $TARGET_FPS"
MONITORS_LIST=$(jq -r 'keys[]' "$WALLPAPER_JSON")

# ==========================================
#           LOGIC BRANCHING
# ==========================================

if [ "$TARGET_FPS" -eq 0 ]; then
    # --------------------------------------
    # OPTION A: STATIC MODE (FPS = 0)
    # --------------------------------------
    echo "FPS target is 0. Switching to static cached images."

    # 1. Kill the heavy engine immediately
    killall -q linux-wallpaperengine

    # 2. Kill any EXISTING swaybg instances so we don't stack them
    killall -q swaybg

    # 3. Apply static wallpapers
    # (We ignore ENABLE_MASK here because without this, screen is black)
    for monitor in $MONITORS_LIST; do
        CURRENT_ID=$(jq -r --arg m "$monitor" '.[$m]' "$WALLPAPER_JSON")
        CACHE_IMG="$CACHE_DIR/${CURRENT_ID}.png"

        if [ -f "$CACHE_IMG" ]; then
            echo "Applying static wallpaper for $monitor..."
            swaybg -o "$monitor" -i "$CACHE_IMG" -m fill > /dev/null 2>&1 &
        else
            echo "Warning: No cache found for $CURRENT_ID on $monitor"
        fi
    done

    exit 0

else
    # --------------------------------------
    # OPTION B: ENGINE MODE (FPS > 0)
    # --------------------------------------

    # Capture OLD PIDs
    OLD_PIDS=$(pgrep -f "linux-wallpaperengine")

    echo "--- Starting Wallpaper Engine ---"

    SWAY_MASK_PIDS=()

    for monitor in $MONITORS_LIST; do
        CURRENT_ID=$(jq -r --arg m "$monitor" '.[$m]' "$WALLPAPER_JSON")
        CACHE_IMG="$CACHE_DIR/${CURRENT_ID}.png"

        # 1. Start Transition Mask (Only if enabled in config)
        if [ "$ENABLE_MASK" = "true" ] && [ -f "$CACHE_IMG" ]; then
            echo "Applying transition mask for $monitor..."
            swaybg -o "$monitor" -i "$CACHE_IMG" -m fill > /dev/null 2>&1 &
            SWAY_MASK_PIDS+=($!)
        elif [ "$ENABLE_MASK" != "true" ]; then
            echo "Transition mask disabled in config."
        fi

        # 2. Check Cache / Generate Screenshot
        if [ ! -f "$CACHE_IMG" ]; then
            echo "Cache missing. Generating screenshot..."
            env XCURSOR_THEME=Bibata-Modern-Classic XCURSOR_SIZE=24 \
            __GL_THREADED_OPTIMIZATIONS=0 \
            linux-wallpaperengine \
                --silent \
                --screen-root "$monitor" \
                --fps "$TARGET_FPS" \
                --screenshot "$CACHE_IMG" \
                "$CURRENT_ID" > /dev/null 2>&1 &
            sleep 0.1
        else
            # 3. Start The Real Engine
            env XCURSOR_THEME=Bibata-Modern-Classic XCURSOR_SIZE=24 \
            __GL_THREADED_OPTIMIZATIONS=0 \
            linux-wallpaperengine \
                --silent \
                --screen-root "$monitor" \
                --fps "$TARGET_FPS" \
                "$CURRENT_ID" > /dev/null 2>&1 &
            sleep 0.1
        fi
    done

    # --- CLEANUP (Only runs if FPS > 0) ---
    echo "Waiting for new wallpapers to initialize..."
    sleep 2

    # 1. Kill ONLY the transition masks we just created
    if [ ${#SWAY_MASK_PIDS[@]} -gt 0 ]; then
        echo "Removing transition mask..."
        kill ${SWAY_MASK_PIDS[@]} 2>/dev/null
    fi

    # 2. Kill old Engine instances
    if [ -n "$OLD_PIDS" ]; then
        echo "Cleaning up old engine instances..."
        kill $OLD_PIDS 2>/dev/null
    fi

    # 3. Kill any lingering swaybg instances
    killall -q swaybg 2>/dev/null
fi
