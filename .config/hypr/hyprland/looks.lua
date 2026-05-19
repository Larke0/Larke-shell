-- ~/.config/hypr/hyprland/looks.lua
-- Converted from looks.conf for Hyprland 0.55+

-- -----------------------------------------------------------------------------
-- 1. Core Window Structures, Shadows, and Gaps
-- -----------------------------------------------------------------------------
hl.config({
  general = {
    gaps_in = 3,
    gaps_out = 8,
    border_size = 2,
    col = {
      -- Type-safe multi-color gradient table
      active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
      inactive_border = "rgba(595959aa)"
    },
    resize_on_border = false,
    allow_tearing = false,
    layout = "dwindle"
  },

  decoration = {
    rounding = 10,
    rounding_power = 2,
    shadow = {
      enabled = true,
      range = 15,
      render_power = 5,
      color = "rgba(1a1a1aee)"
    }
  },

  dwindle = {
    preserve_split = true
  },

  master = {
    new_status = "master"
  },

  misc = {
    force_default_wallpaper = 0,
    disable_hyprland_logo = true
  }
})

-- -----------------------------------------------------------------------------
-- 2. Standalone Bezier Curve Definitions (Hyprland 0.55+ API standard)
-- -----------------------------------------------------------------------------
hl.curve("smoothOut", { type = "bezier", points = { { 0.36, 0 }, { 0.66, -0.56 } } })
hl.curve("smoothIn", { type = "bezier", points = { { 0.25, 1 }, { 0.5, 1 } } })
hl.curve("overshot", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("softSnap", { type = "bezier", points = { { 0.4, 0 }, { 0.2, 1 } } })
hl.curve("fluent", { type = "bezier", points = { { 0.0, 0.0 }, { 0.2, 1.0 } } })

-- -----------------------------------------------------------------------------
-- 3. Standalone Animation Tree Mappings (Hyprland 0.55+ API standard)
-- -----------------------------------------------------------------------------
hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "overshot", style = "popin 80%" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "overshot", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "smoothOut", style = "popin 95%" })

hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "smoothIn" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 4, bezier = "smoothIn" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 4, bezier = "smoothOut" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 4, bezier = "smoothIn" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 4, bezier = "smoothIn" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 4, bezier = "smoothIn" })
hl.animation({ leaf = "fadeDpms", enabled = true, speed = 4, bezier = "smoothIn" })

hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "overshot", style = "slidefade 30%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "overshot", style = "slidefadevert 30%" })
hl.animation({ leaf = "monitorAdded", enabled = true, speed = 5, bezier = "smoothIn" })
