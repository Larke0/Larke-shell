-- ~/Larke-shell/.config/hypr/hyprland/general.lua

hl.config({
  input = {
    accel_profile = "flat",
    sensitivity = -0.8,
    kb_layout = "br",
    kb_variant = "abnt2",
    scroll_factor = 2
  },
  binds = {
    scroll_event_delay = 100
  },
  cursor = {
    no_hardware_cursors = false
  },
  general = {
    gaps_in = 3,
    gaps_out = 8,
    border_size = 2,
    col = {
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
    },
    blur = {
      enabled = true,
      size = 5,
      passes = 2,
      ignore_opacity = true,
      contrast = 1.5,
      brightness = 0.8,
      new_optimizations = true
    }
  },
  dwindle = {
    preserve_split = true
  },
  master = {
    new_status = "master"
  },
  misc = {
    always_follow_on_dnd = true,
    enable_swallow = true,
    focus_on_activate = true,
    force_default_wallpaper = 0,
    disable_hyprland_logo = true
  },
  ecosystem = {
    no_update_news = true,
    enforce_permissions = false
  }
})
