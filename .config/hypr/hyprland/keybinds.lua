-- ~/.config/hypr/hyprland/keybinds.lua
-- Corrected for Hyprland 0.55+

-- -----------------------------------------------------------------------------
-- Local Path & Variable Definitions
-- -----------------------------------------------------------------------------
local terminal = "kitty"
local fileManager = "nautilus --new-window"
--local menu = "rofi -show combi -modes combi -combi-modes 'drun,calc'"
local menu = "caelestia shell drawers toggle launcher"
local browser = "helium"
-- local toggle_scroll = "~/.config/hypr/scripts/toggle_scroll.sh"
local monitor_empty_ws = "~/.config/hypr/scripts/monitor_empty_ws.sh"
local monitor_ws = "~/.config/hypr/scripts/monitor_ws.sh"
local close_special = "~/.config/hypr/scripts/close_special.sh"

local function smart_maximize()
	local win = hl.get_active_window()
	if not win then
		return
	end

	-- Check if window is fullscreen/maximized
	local is_maxed = win.fullscreen == true or (type(win.fullscreen) == "number" and win.fullscreen > 0)

	if is_maxed then
		hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
	elseif win.pinned then
		hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
	elseif win.floating then
		hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
	else
		hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
	end
end

local function disable_scroll()
	hl.config({ input = { scroll_factor = 0 } })
end

local function enable_scroll()
	hl.config({ input = { scroll_factor = 2 } })
end

local function launch_menu()
	-- Ensures scroll is restored when the menu pops up
	hl.config({ input = { scroll_factor = 2 } })
	hl.dispatch(hl.dsp.exec_cmd(menu))
end

-- -----------------------------------------------------------------------------
-- 1. Core App Launchers & System Actions
-- -----------------------------------------------------------------------------
hl.bind("SUPER + T", hl.dsp.exec_cmd(terminal))
hl.bind("SUPER + W", hl.dsp.exec_cmd(browser))
hl.bind("SUPER + E", hl.dsp.exec_cmd(fileManager))
hl.bind("ALT + TAB", hl.dsp.window.cycle_next())
hl.bind("CTRL + SHIFT + Escape", hl.dsp.exec_cmd("kitty --class btop -e btop"))
--hl.bind("SUPER + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind("SUPER + L", hl.dsp.exec_cmd("caelestia shell lock lock"))
hl.bind("SUPER + Q", hl.dsp.exec_cmd("~/.config/hypr/GameWorkspace/scripts/close-window.sh"))
hl.bind("SUPER + SHIFT + Q", hl.dsp.exec_cmd("kill -9 $(hyprctl activewindow -j | jq .pid)"))

-- Clipboard & Screenshots
hl.bind("SUPER + V", hl.dsp.exec_cmd("cliphist list | rofi -dmenu | cliphist decode | wl-copy"))
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh"))
--hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("caelestia screenshot"))

-- Dynamic Application Menu (Triggers on left Super key release)
hl.bind("SUPER + SUPER_L", launch_menu, { release = true })

-- Scroll Sensitivity Mod Flags (No Timers)
hl.bind("SUPER_L", disable_scroll, { non_blocking = true, locked = true, transparent = true })
hl.bind("SUPER + SUPER_L", enable_scroll, { release = true, non_blocking = true, locked = true, transparent = true })

-- -----------------------------------------------------------------------------
-- 2. Directional Matrix (Focus, Move, Resize)
-- -----------------------------------------------------------------------------
local directions = {
	left = { rx = -25, ry = 0 },
	right = { rx = 25, ry = 0 },
	up = { rx = 0, ry = -25 },
	down = { rx = 0, ry = 25 },
}

for dir, res in pairs(directions) do
	hl.bind("SUPER + " .. dir, hl.dsp.focus({ direction = dir }))
	hl.bind("SUPER + ALT + " .. dir, hl.dsp.window.move({ direction = dir }))
	hl.bind("SUPER + SHIFT + " .. dir, hl.dsp.window.resize({ x = res.rx, y = res.ry, relative = true }))
end

-- Window Layout States
hl.bind("SUPER + ALT + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + F", smart_maximize)
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

-- Interactive Mouse Drag Binds
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- -----------------------------------------------------------------------------
-- 3. Special Workspaces
-- -----------------------------------------------------------------------------
local special_workspaces = {
	P = "Whatsapp",
	D = "discord",
	S = "spotify",
	m = "mixer",
}

for key, name in pairs(special_workspaces) do
	hl.bind("SUPER + " .. key, hl.dsp.workspace.toggle_special(name))
end

-- Minimize any open special workspace
hl.bind("SUPER + A", hl.dsp.exec_cmd(close_special))

-- -----------------------------------------------------------------------------
-- 4. Monitor Workspace Navigation & Mouse-Wheel Hooks
-- -----------------------------------------------------------------------------
local wheel_nav = {
	down = { val = "-1", key = "left" },
	up = { val = "+1", key = "right" },
}

for dir, nav in pairs(wheel_nav) do
	-- Mouse wheel binds
	hl.bind("SUPER + SHIFT + mouse_" .. dir, hl.dsp.focus({ workspace = "m" .. nav.val }))
	hl.bind("SUPER + mouse_" .. dir, hl.dsp.exec_cmd(monitor_ws .. " workspace " .. nav.val))
	hl.bind("SUPER + ALT + mouse_" .. dir, hl.dsp.exec_cmd(monitor_ws .. " movetoworkspace " .. nav.val))
	-- Keyboard equivalents
	hl.bind("SUPER + CTRL + " .. nav.key, hl.dsp.exec_cmd(monitor_ws .. " workspace " .. nav.val))
end

hl.bind("SUPER + X", hl.dsp.exec_cmd(monitor_empty_ws))
hl.bind("SUPER + ALT + X", hl.dsp.exec_cmd(monitor_empty_ws .. " move"))

-- -----------------------------------------------------------------------------
-- 5. Numeric Workspace Loops (1-10)
-- -----------------------------------------------------------------------------
for i = 1, 10 do
	-- Maps 10 to the '0' key for ergonomic standard layout
	local key = (i == 10) and "0" or tostring(i)

	hl.bind("SUPER + " .. key, hl.dsp.exec_cmd(monitor_ws .. " workspace " .. i))
	hl.bind("SUPER + ALT + " .. key, hl.dsp.exec_cmd(monitor_ws .. " movetoworkspace " .. i))
end

-- -----------------------------------------------------------------------------
-- 6. Audio Controls & System Hardware Keys
-- -----------------------------------------------------------------------------
local hardware_keys = {
	{
		key = "XF86AudioRaiseVolume",
		cmd = "wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+ && touch /tmp/qs-vol-trigger",
		opts = { repeating = true },
	},
	{
		key = "XF86AudioLowerVolume",
		cmd = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && touch /tmp/qs-vol-trigger",
		opts = { repeating = true },
	},
	{
		key = "XF86AudioMute",
		cmd = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && touch /tmp/qs-vol-trigger",
		opts = {},
	},
	{
		key = "XF86AudioMicMute",
		cmd = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",
		opts = { repeating = true, locked = true },
	},
	{
		key = "XF86MonBrightnessUp",
		cmd = "brightnessctl -e4 -n2 set 5%+",
		opts = { repeating = true, locked = true },
	},
	{
		key = "XF86MonBrightnessDown",
		cmd = "brightnessctl -e4 -n2 set 5%-",
		opts = { repeating = true, locked = true },
	},
	{
		key = "XF86AudioNext",
		cmd = "playerctl next",
		opts = { locked = true },
	},
	{
		key = "XF86AudioPause",
		cmd = "playerctl play-pause",
		opts = { locked = true },
	},
	{
		key = "XF86AudioPlay",
		cmd = "playerctl play-pause",
		opts = { locked = true },
	},
	{
		key = "XF86AudioPrev",
		cmd = "playerctl previous",
		opts = { locked = true },
	},
}

for _, hw in ipairs(hardware_keys) do
	-- Falls back to an empty table {} if opts are not specified
	hl.bind(hw.key, hl.dsp.exec_cmd(hw.cmd), hw.opts or {})
end
