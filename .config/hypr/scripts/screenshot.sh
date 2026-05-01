#!/usr/bin/env bash

# 1. Cleanup
TEMP_FILE="/tmp/screenshot_$(date +%s).png"
pkill -x still
pkill -x slurp

# 2. The Capture
# We run grim and slurp INSIDE still.
# We don't pipe to swappy here so 'still' can exit immediately after capture.
still -c "grim -g \"\$(slurp -d -b 1e1e2e80 -c b4befeff -w 2; sleep .3)\" $TEMP_FILE"

# 3. The Escape/Failsafe Check
# If the file doesn't exist (because you hit Escape), or is empty, we just quit.
if [ ! -s "$TEMP_FILE" ]; then
  rm -f "$TEMP_FILE"
  pkill -x still # Extra safety to ensure screen is unfrozen
  exit 0
fi

# 4. The Editor
# Now that 'still' has finished and the screen is unfrozen, open the editor.
swappy -f "$TEMP_FILE" -o - | wl-copy

# 5. Final Cleanup
rm "$TEMP_FILE"
