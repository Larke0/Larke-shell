-- ~/Larke-shell/.config/hypr/GameWorkspace/init.lua
-- Master Profile Entry Point for the Gaming Sub-Module

local home     = os.getenv("HOME")

-- Global module environment variables (accessible by required subfiles)
game_workspace = home .. "/.config/hypr/GameWorkspace"
scripts        = game_workspace .. "/scripts"
main_monitor   = "DP-3"
blur_enabled   = true

-- Load the core workspace profiles
require("GameWorkspace/general")
require("GameWorkspace/execs")
require("GameWorkspace/keybinds")

-- Safely protect against runtime failure if game-rules doesn't exist yet
pcall(require, "GameWorkspace/scripts/game-rules")
