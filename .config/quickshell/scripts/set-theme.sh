#!/usr/bin/env bash

# 1. Get current wallpaper
WALLPAPER=$(awww query | awk -F 'image: ' '{print $2}' | head -n 1)
[ -z "$WALLPAPER" ] && exit 1

# 2. Run Matugen for Quickshell and GTK
matugen image "$WALLPAPER"

# 3. Get the dominant color name from Matugen
# This gets the color 'accent' from the quickshell theme
HEX=$(grep "property color accent:" ~/.config/quickshell/theme/Theme.qml | cut -d '"' -f 2)

# 4. Map Matugen color names to Papirus folder colors
case $COLOR in
    "blue"|"cyan") ICON_COLOR="cyan" ;;
    "green") ICON_COLOR="green" ;;
    "red"|"orange") ICON_COLOR="orange" ;;
    "magenta"|"pink") ICON_COLOR="magenta" ;;
    "yellow") ICON_COLOR="yellow" ;;
    *) ICON_COLOR="grey" ;; # Default fallback
esac

# 5. Apply the icon color
#papirus-folders -C "$ICON_COLOR" --theme Papirus-Dark
