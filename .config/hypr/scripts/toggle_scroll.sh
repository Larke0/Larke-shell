#!/usr/bin/env bash
# ==============================================================================
# Script: Scroll Sensitivity Dynamic Toggler (PID & State Managed)
# ==============================================================================

PID_FILE="/tmp/hypr_scroll_timer.pid"

if [ "$1" == "off" ]; then
  # 1. Dynamically lower scroll factor to 0
  hyprctl eval 'hl.config({ input = { scroll_factor = 0 } })'

  # 2. Kill previous safety timer if it exists so they don't stack
  if [ -f "$PID_FILE" ]; then
    kill $(cat "$PID_FILE") 2>/dev/null
  fi

  # 3. Start a new 5-second safety timer in the background
  (
    sleep 1
    hyprctl eval 'hl.config({ input = { scroll_factor = 2 } })'
    rm -f "$PID_FILE"
  ) &

  # 4. Save the PID of the background process
  echo $! >"$PID_FILE"

else
  # 1. Restore to standard profile instantly
  hyprctl eval 'hl.config({ input = { scroll_factor = 2 } })'

  # 2. Intercept and kill the background safety timer
  if [ -f "$PID_FILE" ]; then
    kill $(cat "$PID_FILE") 2>/dev/null
    rm -f "$PID_FILE"
  fi
fi
