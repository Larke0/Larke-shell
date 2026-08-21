-- ~/Larke-shell/.config/hypr/hyprland/execs.lua

hl.on("hyprland.start", function()
	-- Security & Authentication
	hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
	hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
	hl.exec_cmd("sleep 0.5 && hyprlock")

	-- Background Utilities
	hl.exec_cmd("hypridle")
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd("awww restore")
	--  hl.exec_cmd("quickshell")

	hl.exec_cmd("caelestia shell -d")
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
	hl.exec_cmd("fcitx5")

	-- Theming and State Sync
	hl.exec_cmd("sleep 1 && ~/.config/quickshell/scripts/set-theme.sh")
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

	-- Autoload Keyboard Mapping profile rules
	hl.exec_cmd("sleep 3 && input-remapper-control --command autoload")

	-- Local Plugin Engine Reload
	hl.exec_cmd("sleep 3 && hyprpm reload -n")
end)
