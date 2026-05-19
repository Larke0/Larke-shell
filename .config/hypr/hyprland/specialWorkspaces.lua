-- ~/Larke-shell/.config/hypr/hyprland/specialWorkspaces.lua
-- Special Workspace Assignment and Auto-Spawning Hooks

-- 1. Whatsapp / ZapZap
hl.window_rule({ match = { class = "^(com.rtosta.zapzap)$" }, workspace = "special:Whatsapp" })
hl.window_rule({ match = { class = "^(org.telegram.desktop)$" }, workspace = "special:Whatsapp" })
hl.workspace_rule({ workspace = "special:Whatsapp", on_created_empty = "flatpak run com.rtosta.zapzap" })

-- 2. Discord Focus Layer
hl.window_rule({ match = { class = "^(discord)$" }, workspace = "special:discord" })
hl.window_rule({ match = { initial_class = "^(discord)$" }, workspace = "special:discord" })
hl.window_rule({ match = { initial_title = "^(Discord)$" }, workspace = "special:discord" })
hl.workspace_rule({ workspace = "special:discord", on_created_empty = "discord" })

-- 3. Audio Mixer Panel
hl.window_rule({ match = { class = "^(com.saivert.pwvucontrol)$" }, workspace = "special:mixer" })
hl.workspace_rule({ workspace = "special:mixer", on_created_empty = "pwvucontrol" })

-- 4. Spotify Daemon
hl.window_rule({ match = { class = "^([sS]potify)$" }, workspace = "special:spotify" })
hl.workspace_rule({ workspace = "special:spotify", on_created_empty = "spotify" })
