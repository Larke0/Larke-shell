#!/usr/bin/env bash

# --- CONFIGURATION ---
JSON_FILE="$HOME/.config/hypr/GameWorkspace/scripts/game-list.json"
RULES_FILE="$HOME/.config/hypr/GameWorkspace/scripts/game-rules.conf"

# --- CHECK FOR JQ ---
if ! command -v jq &> /dev/null; then
    echo "Error: 'jq' is not installed." >&2
    exit 1
fi

# --- START SCRIPT ---
echo "Generating '$RULES_FILE' from '$JSON_FILE'..."

{
  echo "# --- Special Workspace Rules for Games ---"
  echo "# AUTO-GENERATED. Do not edit directly."
  echo ""
  echo "# GLOBAL RULES: Optimization for Game Workspace"
  echo "# 'renderunfocused' keeps games running even when you toggle the workspace off"
  echo "#windowrule = workspace special:games, renderunfocused"
  echo "#windowrule = workspace special:games, noblur"
  echo "#windowrule = workspace special:games, noanim"
  echo ""
  echo "# Rule for all Steam Proton games"
  echo "windowrule = workspace special:games, match:class ^(steam_app_)"
  echo ""
} > "$RULES_FILE"

# Read JSON objects looking for initial_class, initial_title AND app_class
# We use pipes | as separators
jq -r '.[] | "\(.initial_class)|\(.initial_title)|\(.app_class)"' "$JSON_FILE" | while IFS="|" read -r game_initial_class game_title game_app_class; do

  if [ -n "$game_initial_class" ] && [ -n "$game_title" ] && [ "$game_initial_class" != "null" ]; then

    echo "# --- Entry: $game_title ---" >> "$RULES_FILE"

    # 1. RULE A: MATCH BY INITIAL CLASS
    # Build case-insensitive regex for initial class
    f_char_lower=$(echo "${game_initial_class:0:1}" | tr '[:upper:]' '[:lower:]')
    f_char_upper=$(echo "${game_initial_class:0:1}" | tr '[:lower:]' '[:upper:]')
    rest_class=$(echo "${game_initial_class:1}")
    initial_class_regex="^(([$f_char_lower$f_char_upper])$rest_class)$"

    echo "windowrule = workspace special:games, match:initial_class $initial_class_regex" >> "$RULES_FILE"

    # 2. RULE B: MATCH BY INITIAL TITLE
    safe_title=$(echo "$game_title" | sed 's/[][\.^$*+?()|{}]/\\&/g')
    title_regex="^($safe_title)$"

    echo "windowrule = workspace special:games, match:initial_title $title_regex" >> "$RULES_FILE"

    # 3. RULE C: MATCH BY APP CLASS (Current Class)
    if [ -n "$game_app_class" ] && [ "$game_app_class" != "null" ]; then
        # Build case-insensitive regex for app class
        ac_f_char_lower=$(echo "${game_app_class:0:1}" | tr '[:upper:]' '[:lower:]')
        ac_f_char_upper=$(echo "${game_app_class:0:1}" | tr '[:lower:]' '[:upper:]')
        ac_rest_class=$(echo "${game_app_class:1}")
        app_class_regex="^(([$ac_f_char_lower$ac_f_char_upper])$ac_rest_class)$"

        # Note: We use the standard 'class:' selector here
        echo "windowrule = workspace special:games, match:class $app_class_regex" >> "$RULES_FILE"
    fi

    echo "" >> "$RULES_FILE"

  fi
done

echo "✅ '$RULES_FILE' has been generated."

# --- RELOAD HYPRLAND ---
hyprctl reload
