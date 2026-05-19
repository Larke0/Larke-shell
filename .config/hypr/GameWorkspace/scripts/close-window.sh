#!/usr/bin/env bash

if ! command -v jq &>/dev/null; then
  notify-send "Error" "jq is missing."
  exit 1
fi

WINDOW_INFO=$(hyprctl activewindow -j)
CLASS=$(echo "$WINDOW_INFO" | jq -r ".class")
PID=$(echo "$WINDOW_INFO" | jq -r ".pid")
ADDRESS=$(echo "$WINDOW_INFO" | jq -r ".address")
TARGETS=("gamescope")
FORCE_KILL=0

for target in "${TARGETS[@]}"; do
  if [[ "$CLASS" == *"$target"* ]]; then
    FORCE_KILL=1
    break
  fi
done

if [[ "$FORCE_KILL" -eq 1 ]]; then
  kill -9 "$PID"
else
  # Upgraded to utilize type-safe native window target closures
  hyprctl dispatch "hl.dsp.window.close({ window = 'address:$ADDRESS' })"
fi
