#!/usr/bin/env bash

# --- CONFIGURATION ---
JSON_FILE="$HOME/.config/hypr/GameWorkspace/scripts/game-list.json"
RULES_FILE="$HOME/.config/hypr/GameWorkspace/scripts/game-rules.lua"

# --- CHECK FOR JQ ---
if ! command -v jq &>/dev/null; then
  echo "Error: 'jq' is not installed." >&2
  exit 1
fi

# --- START SCRIPT ---
echo "Generating '$RULES_FILE' from '$JSON_FILE'..."

{
  echo "-- --- Special Workspace Rules for Games ---"
  echo "-- AUTO-GENERATED. Do not edit directly."
  echo ""
  echo "-- Global rule for all Steam Proton games"
  echo "hl.window_rule({ match = { class = [[^(steam_app_)]] }, workspace = \"special:games\" })"
  echo ""
} >"$RULES_FILE"

# Read JSON objects looking for initial_class, initial_title AND app_class
jq -r '.[] | "\(.initial_class)|\(.initial_title)|\(.app_class)"' "$JSON_FILE" | while IFS="|" read -r game_initial_class game_title game_app_class; do

  if [ -n "$game_initial_class" ] && [ -n "$game_title" ] && [ "$game_initial_class" != "null" ]; then

    echo "-- --- Entry: $game_title ---" >>"$RULES_FILE"

    # 1. RULE A: MATCH BY INITIAL CLASS (Wrapped in Lua raw string brackets)
    f_char_lower=$(echo "${game_initial_class:0:1}" | tr '[:upper:]' '[:lower:]')
    f_char_upper=$(echo "${game_initial_class:0:1}" | tr '[:lower:]' '[:upper:]')
    rest_class=$(echo "${game_initial_class:1}")
    initial_class_regex="^(([$f_char_lower$f_char_upper])$rest_class)$"

    echo "hl.window_rule({ match = { initial_class = [[$initial_class_regex]] }, workspace = \"special:games\" })" >>"$RULES_FILE"

    # 2. RULE B: MATCH BY INITIAL TITLE (Wrapped in Lua raw string brackets)
    safe_title=$(echo "$game_title" | sed 's/[][\.^$*+?()|{}]/\\&/g')
    title_regex="^($safe_title)$"

    echo "hl.window_rule({ match = { initial_title = [[$title_regex]] }, workspace = \"special:games\" })" >>"$RULES_FILE"

    # 3. RULE C: MATCH BY APP CLASS (Wrapped in Lua raw string brackets)
    if [ -n "$game_app_class" ] && [ "$game_app_class" != "null" ]; then
      ac_f_char_lower=$(echo "${game_app_class:0:1}" | tr '[:upper:]' '[:lower:]')
      ac_f_char_upper=$(echo "${game_app_class:0:1}" | tr '[:lower:]' '[:upper:]')
      ac_rest_class=$(echo "${game_app_class:1}")
      app_class_regex="^(([$ac_f_char_lower$ac_f_char_upper])$ac_rest_class)$"

      echo "hl.window_rule({ match = { class = [[$app_class_regex]] }, workspace = \"special:games\" })" >>"$RULES_FILE"
    fi

    echo "" >>"$RULES_FILE"
  fi
done

echo "✅ '$RULES_FILE' has been generated."
hyprctl reload
