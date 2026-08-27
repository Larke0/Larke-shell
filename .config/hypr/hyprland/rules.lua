-- ~/Larke-shell/.config/hypr/hyprland/rules.lua

-- Base Safety Rules
hl.window_rule({
	name = "suppress-maximize-events",
	match = { class = ".*" },
	suppress_event = "maximize",
})

-- Performance Tiling Overrides
hl.window_rule({ match = { class = "^(psim.exe)$" }, float = false })
hl.window_rule({ match = { class = "^(simview.exe)$" }, float = false })
hl.window_rule({ match = { class = "^(Minecraft.*)", title = "^(Minecraft*)" }, float = false })
hl.window_rule({ match = { class = "^(com-cburch-logisim-Main)$" }, float = true })
hl.window_rule({ match = { initial_class = "^(Quartus)$", initial_title = "^(Quartus II 32-bit)$" }, float = true })

-- Application Layout Modifiers
hl.window_rule({
	match = { title = "^(Picture-in-Picture)$" },
	float = true,
	pin = true,
	size = { 772, 432 },
})

hl.window_rule({
	match = { class = "^(hyprland-share-picker)$" },
	pin = true,
	stay_focused = true,
	focus_on_activate = true,
})

-- Media & Gaming Focus Performance Rules
hl.window_rule({ match = { class = "^(ffxiv_dx11.exe)$" }, render_unfocused = true })
hl.window_rule({ match = { class = "^(discord)$" }, render_unfocused = true })
hl.window_rule({ match = { title = "^(Vtube Studio)", class = "^(steam_app_1325860)" }, render_unfocused = true })

-- Blur Exclusion Layer
hl.window_rule({ match = { class = ".*" }, no_blur = true })
hl.window_rule({ match = { class = "^(kitty)$" }, no_blur = false })
hl.window_rule({ match = { class = "^(btop)$" }, no_blur = false })

hl.window_rule({ match = { class = "^(steam)$" }, float = true })
hl.window_rule({ match = { class = "^(steam)$", initial_title = "^(Steam)$" }, float = false })
