#!/usr/bin/env bash
# ==============================================================================
# Script: Scroll Sensitivity Dynamic Toggler (Hyprland 0.55+ Lua Update)
# ==============================================================================

if [ "$1" == "off" ]; then
  # Dynamically lower scroll factor to 0 via Lua evaluation
  hyprctl eval 'hl.config({ input = { scroll_factor = 0 } })'

  # Auto-restore after 5 seconds no matter what
  (sleep 5 && hyprctl eval 'hl.config({ input = { scroll_factor = 2 } })') &
else
  # Restore to your standard flat profile factor (2)
  hyprctl eval 'hl.config({ input = { scroll_factor = 2 } })'
fi
