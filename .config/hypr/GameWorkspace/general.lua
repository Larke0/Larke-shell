-- ~/Larke-shell/.config/hypr/GameWorkspace/general.lua

-- Force the 'special:games' workspace to always anchor to your AOC display
hl.workspace_rule({ workspace = "special:games", monitor = main_monitor, default = true })

-- Dynamic profile decoration styling definitions
hl.config({
  decoration = {
    blur = {
      enabled = blur_enabled,
      size = 5,
      passes = 2,
      ignore_opacity = false,
      noise = 0.08,
      contrast = 1.5,
      brightness = 0.8,
      xray = false,
      new_optimizations = true
    }
  }
})
