#!/usr/bin/env bash

# Check if the second argument ($1) is exactly "yes"
if [ "$1" == "yes" ]; then
    NORMAL_BLUR="true"
else
    NORMAL_BLUR="false"
fi

# Listen to the socket for workspace changes
socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do

    # Check if the event is about the special workspace
    if [[ "$line" == "activespecial>>special:games"* ]]; then
        # GAMEMODE ON: Disable blur and force opacity to 1.0
        hyprctl keyword decoration:blur:enabled false
        echo "Gamemode Enabled"

    elif [[ "$line" == "activespecial>>,"* ]]; then
        # GAMEMODE OFF: Revert to normal settings
        hyprctl keyword decoration:blur:enabled $NORMAL_BLUR
        echo "Gamemode Disabled"
    fi
done
