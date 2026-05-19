#!/usr/bin/env bash

if [ "$1" == "yes" ]; then
  NORMAL_BLUR="true"
else
  NORMAL_BLUR="false"
fi

socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do

  if [[ "$line" == "activespecial>>special:games"* ]]; then
    # GAMEMODE ON: Disable blur via top-level evaluation table properties
    hyprctl eval "hl.config({ decoration = { blur = { enabled = false } } })"
    echo "Gamemode Enabled"

  elif [[ "$line" == "activespecial>>,"* ]]; then
    # GAMEMODE OFF: Revert to your custom user profile factor state
    hyprctl eval "hl.config({ decoration = { blur = { enabled = $NORMAL_BLUR } } })"
    echo "Gamemode Disabled"
  fi
done
