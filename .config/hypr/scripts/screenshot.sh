#!/usr/bin/env bash

# 1. Export the styling so grimblast natively picks it up
export SLURP_ARGS="-d -b 000000CC -c b4befeff -w 2"

# 2. Setup temp file
TEMP_FILE="/tmp/screenshot_$(date +%s).png"

# 3. The Capture & Failsafe
# grimblast returns 0 if successful, or aborts if you press Escape
if grimblast --freeze -w 0.2 save area "$TEMP_FILE"; then

  # Open in swappy, and pipe the saved output to clipboard
  swappy -f "$TEMP_FILE" -o - | wl-copy

  # Clean up after swappy closes
  rm -f "$TEMP_FILE"
else
  # You pressed Escape or it failed, just clean up
  rm -f "$TEMP_FILE"
fi
