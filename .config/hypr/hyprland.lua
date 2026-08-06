-- ~/Larke-shell/.config/hypr/hyprland.lua

-- 0. Source Per-Host Profile FIRST to register your monitor variables
require("custom/hyprland")

-- 1. Initial Environment Profiles
require("hyprland/env")

-- 2. Hardware, Gaps, Aesthetics & Structural Behaviors
require("hyprland/general")
require("hyprland/rules")
require("hyprland/looks")
require("hyprland/theme")

-- 3. Hotkeys Mappings Configuration Engine
require("hyprland/keybinds")

-- 4. Process Execution & System Hook Activations
require("hyprland/execs")

-- 5. Special Workspace Rules and Launchers
require("hyprland/specialWorkspaces")

-- 6. Window Event Mitigations & Screencopy Capability Matrix
require("hyprland/permissions")

-- 7. Load Gaming Environment Workspace Sub-Module
-- require("GameWorkspace")
