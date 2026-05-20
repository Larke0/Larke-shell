-- ~/Larke-shell/.config/hypr/hyprland/keybinds.lua
-- Corrected for Hyprland 0.55+ (Completely Removed Hyprsplit)

-- Local Path & Variable Definitions
local terminal         = "kitty"
local fileManager      = "nautilus --new-window"
local menu             = "rofi -show combi -modes combi -combi-modes 'drun,calc'"
local browser          = "helium"
local toggle_scroll    = "~/.config/hypr/scripts/toggle_scroll.sh"
local monitor_empty_ws = "~/.config/hypr/scripts/monitor_empty_ws.sh"
local monitor_ws       = "~/.config/hypr/scripts/monitor_ws.sh"

-- 1. Core App Launchers (Fixed variable expansions)
hl.bind("SUPER + T", hl.dsp.exec_cmd(terminal))
hl.bind("SUPER + W", hl.dsp.exec_cmd(browser))
hl.bind("SUPER + E", hl.dsp.exec_cmd(fileManager))
hl.bind("ALT + TAB", hl.dsp.window.cycle_next())
hl.bind("CTRL + SHIFT + Escape", hl.dsp.exec_cmd("kitty --class btop -e btop"))
hl.bind("SUPER + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind("SUPER + Q", hl.dsp.exec_cmd("~/.config/hypr/GameWorkspace/scripts/close-window.sh"))
hl.bind("SUPER + SHIFT + Q", hl.dsp.exec_cmd("kill -9 $(hyprctl activewindow -j | jq .pid)"))

-- Clipboard & Screenshots
hl.bind("SUPER + V", hl.dsp.exec_cmd("cliphist list | rofi -dmenu | cliphist decode | wl-copy"))
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh"))

-- Dynamic Application Menu (Triggers on left Super key release)
hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd(toggle_scroll .. " on; " .. menu), { release = true })

-- 2. Focus & Window Management (Spelled out directions)
hl.bind("SUPER + left", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + right", hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + up", hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + down", hl.dsp.focus({ direction = "down" }))

hl.bind("SUPER + ALT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind("SUPER + ALT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind("SUPER + ALT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind("SUPER + ALT + down", hl.dsp.window.move({ direction = "down" }))

hl.bind("SUPER + SHIFT + left", hl.dsp.window.resize({ x = -25, y = 0 }))
hl.bind("SUPER + SHIFT + right", hl.dsp.window.resize({ x = 25, y = 0 }))
hl.bind("SUPER + SHIFT + up", hl.dsp.window.resize({ x = 0, y = -25 }))
hl.bind("SUPER + SHIFT + down", hl.dsp.window.resize({ x = 0, y = 25 }))

-- Window Layout States
hl.bind("SUPER + ALT + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

-- 3. Interactive Mouse Drag Binds (Fixed dispatchers)
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- 4. Special Workspaces Toggles
hl.bind("SUPER + P", hl.dsp.workspace.toggle_special("Whatsapp"))
hl.bind("SUPER + D", hl.dsp.workspace.toggle_special("discord"))
hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("spotify"))
hl.bind("SUPER + M", hl.dsp.workspace.toggle_special("mixer"))

-- 5. Audio Controls & System Hardware Keys
hl.bind("XF86AudioRaiseVolume",
  hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+ && touch /tmp/qs-vol-trigger"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && touch /tmp/qs-vol-trigger"),
  { repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && touch /tmp/qs-vol-trigger"))

hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
  { repeating = true, locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { repeating = true, locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { repeating = true, locked = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- 6. Monitor Workspace Navigations & Mouse-Wheel Hooks
hl.bind("SUPER + SHIFT + mouse_down", hl.dsp.focus({ workspace = "m-1" }))
hl.bind("SUPER + SHIFT + mouse_up", hl.dsp.focus({ workspace = "m+1" }))

hl.bind("SUPER + mouse_down", hl.dsp.exec_cmd(monitor_ws .. " workspace -1"))
hl.bind("SUPER + mouse_up", hl.dsp.exec_cmd(monitor_ws .. " workspace +1"))
hl.bind("SUPER + ALT + mouse_down", hl.dsp.exec_cmd(monitor_ws .. " movetoworkspace -1"))
hl.bind("SUPER + ALT + mouse_up", hl.dsp.exec_cmd(monitor_ws .. " movetoworkspace +1"))

hl.bind("SUPER + CTRL + left", hl.dsp.exec_cmd(monitor_ws .. " workspace -1"))
hl.bind("SUPER + CTRL + right", hl.dsp.exec_cmd(monitor_ws .. " workspace +1"))

hl.bind("SUPER + X", hl.dsp.exec_cmd(monitor_empty_ws))
hl.bind("SUPER + ALT + X", hl.dsp.exec_cmd(monitor_empty_ws .. " move"))

-- 7. Workspace Loops Arrays (1-10)
for i = 1, 9 do
  hl.bind("SUPER + " .. i, hl.dsp.exec_cmd(monitor_ws .. " workspace " .. i))
  hl.bind("SUPER + ALT + " .. i, hl.dsp.exec_cmd(monitor_ws .. " movetoworkspace " .. i))
end
hl.bind("SUPER + 0", hl.dsp.exec_cmd(monitor_ws .. " workspace 10"))
hl.bind("SUPER + ALT + 0", hl.dsp.exec_cmd(monitor_ws .. " movetoworkspace 10"))

-- 8. Scroll Sensitivity Mod Flags
hl.bind("SUPER_L", hl.dsp.exec_cmd(toggle_scroll .. " off"), { non_blocking = true, locked = true, transparent = true })
hl.bind("SUPER_L", hl.dsp.exec_cmd(toggle_scroll .. " on"),
  { release = true, non_blocking = true, locked = true, transparent = true })
