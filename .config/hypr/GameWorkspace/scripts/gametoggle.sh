#!/usr/bin/env bash

MAIN_MONITOR="$1"
ENABLE_FULLSCREEN_RESTORE=false

GAME_CACHE_FILE="/tmp/hypr_fullscreen_game"
FOCUS_CACHE_FILE="/tmp/hypr_last_focus"

monitor_info=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true)')
current_monitor_name=$(echo "$monitor_info" | jq -r '.name')
active_special=$(echo "$monitor_info" | jq -r '.specialWorkspace.name')

if [[ "$active_special" == "special:games" ]]; then
  # ==========================================================
  # CASE: CLOSING (Game -> Desktop)
  # ==========================================================
  if [ "$ENABLE_FULLSCREEN_RESTORE" = true ]; then
    window_info=$(hyprctl activewindow -j)
    is_fullscreen=$(echo "$window_info" | jq -r '.fullscreen')
    window_addr=$(echo "$window_info" | jq -r '.address')

    if [[ "$is_fullscreen" == "1" || "$is_fullscreen" == "2" ]]; then
      echo "$window_addr $is_fullscreen" >"$GAME_CACHE_FILE"
      if [[ "$is_fullscreen" == "1" ]]; then
        hyprctl dispatch "hl.dsp.window.fullscreen({ mode = 'maximized' })"
      else
        hyprctl dispatch "hl.dsp.window.fullscreen({ mode = 'fullscreen' })"
      fi
      sleep 0.1
    else
      rm -f "$GAME_CACHE_FILE"
    fi
  else
    rm -f "$GAME_CACHE_FILE"
  fi

  # Toggle Workspace (Hide it via the native Lua sub-table API)
  hyprctl dispatch "hl.dsp.workspace.toggle_special('games')"
  sleep 0.05

  if [[ -f "$FOCUS_CACHE_FILE" ]]; then
    read last_window saved_monitor <"$FOCUS_CACHE_FILE"
    target_ws=$(hyprctl clients -j | jq -r ".[] | select(.address == \"$last_window\") | .workspace.name")

    if [[ "$target_ws" == "special:games" ]]; then
      hyprctl dispatch "hl.dsp.focus({ monitor = '$current_monitor_name' })"
    else
      if [[ -n "$saved_monitor" ]]; then
        hyprctl dispatch "hl.dsp.focus({ monitor = '$saved_monitor' })"
      fi
      sleep 0.05
      hyprctl dispatch "hl.dsp.focus({ window = 'address:$last_window' })"

      window_geo=$(hyprctl clients -j | jq -r ".[] | select(.address == \"$last_window\") | \"\(.at[0]) \(.at[1]) \(.size[0]) \(.size[1])\"")
      if [[ -n "$window_geo" ]]; then
        read x y w h <<<"$window_geo"
        center_x=$((x + w / 2))
        center_y=$((y + h / 2))
        hyprctl dispatch "hl.dsp.cursor.move({ x = $center_x, y = $center_y, absolute = true })"
      fi
    fi
    rm -f "$FOCUS_CACHE_FILE"
  else
    hyprctl dispatch "hl.dsp.focus({ monitor = '$current_monitor_name' })"
  fi

else
  # ==========================================================
  # CASE: OPENING (Desktop -> Game)
  # ==========================================================
  game_count=$(hyprctl clients -j | jq '[.[] | select(.workspace.name == "special:games")] | length')
  if [[ "$game_count" -eq 0 ]]; then
    notify-send -t 2000 "Game Mode" "No games running!"
    exit 0
  fi

  window_info=$(hyprctl activewindow -j)
  current_addr=$(echo "$window_info" | jq -r '.address')

  if [[ "$current_addr" != "null" && -n "$current_addr" ]]; then
    cursor_pos=$(hyprctl cursorpos -j)
    cx=$(echo "$cursor_pos" | jq '.x')
    cy=$(echo "$cursor_pos" | jq '.y')
    wx=$(echo "$window_info" | jq '.at[0]')
    wy=$(echo "$window_info" | jq '.at[1]')
    ww=$(echo "$window_info" | jq '.size[0]')
    wh=$(echo "$window_info" | jq '.size[1]')

    if ((cx >= wx && cx <= wx + ww && cy >= wy && cy <= wy + wh)); then
      echo "$current_addr $current_monitor_name" >"$FOCUS_CACHE_FILE"
    else
      rm -f "$FOCUS_CACHE_FILE"
    fi
  else
    rm -f "$FOCUS_CACHE_FILE"
  fi

  if [ -n "$MAIN_MONITOR" ]; then
    main_monitor_special=$(hyprctl monitors -j | jq -r ".[] | select(.name == \"$MAIN_MONITOR\") | .specialWorkspace.name")
    hyprctl dispatch "hl.dsp.focus({ monitor = '$MAIN_MONITOR' })"
    sleep 0.05
    if [[ "$main_monitor_special" != "special:games" ]]; then
      hyprctl dispatch "hl.dsp.workspace.toggle_special('games')"
    fi
  else
    hyprctl dispatch "hl.dsp.workspace.toggle_special('games')"
  fi

  sleep 0.0
  game_address=$(hyprctl clients -j | jq -r '.[] | select(.workspace.name == "special:games") | .address' | head -n 1)

  if [ "$ENABLE_FULLSCREEN_RESTORE" = true ] && [[ -f "$GAME_CACHE_FILE" ]]; then
    read saved_addr saved_state <"$GAME_CACHE_FILE"
    if [[ "$game_address" == "$saved_addr" ]]; then
      hyprctl dispatch "hl.dsp.focus({ window = 'address:$game_address' })"
      current_fs_state=$(hyprctl clients -j | jq -r ".[] | select(.address == \"$game_address\") | .fullscreen")

      if [[ "$current_fs_state" == "0" ]]; then
        sleep 0.1
        if [[ "$saved_state" == "1" ]]; then
          hyprctl dispatch "hl.dsp.window.fullscreen({ mode = 'maximized' })"
        elif [[ "$saved_state" == "2" ]]; then
          hyprctl dispatch "hl.dsp.window.fullscreen({ mode = 'fullscreen' })"
        fi
      fi
    fi
    rm -f "$GAME_CACHE_FILE"
  elif [[ -n "$game_address" ]]; then
    hyprctl dispatch "hl.dsp.focus({ window = 'address:$game_address' })"
  fi
fi
