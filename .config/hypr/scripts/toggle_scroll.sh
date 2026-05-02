#!/usr/bin/env bash

if [ "$1" == "off" ]; then
  hyprctl keyword input:scroll_factor 0

  # Auto-restore after 2 seconds no matter what
  (sleep 5 && hyprctl keyword input:scroll_factor 1) &
else
  hyprctl keyword input:scroll_factor 1
fi
