-- ~/Larke-shell/.config/hypr/hyprland/permissions.lua
-- Global Window Mitigations, Drag Corrections & Security Matrix

-- -----------------------------------------------------------------------------
-- 1. Core Structural Window Rules (Event Suppressions & Positioning)
-- -----------------------------------------------------------------------------

-- Prevent all applications from firing disruptive maximize requests
hl.window_rule({
  match = { class = ".*" },
  suppress_event = "maximize"
})

-- Critical XWayland Drag Correction Rule
hl.window_rule({
  match = {
    class = "^$",
    title = "^$",
    xwayland = true,
    float = true,
    fullscreen = false,
    pin = false
  },
  no_focus = true
})

-- Dynamic placement handler for the hyprland-run interface utility
hl.window_rule({
  match = { class = "hyprland-run" },
  move = "20 monitor_h-120",
  float = true
})

-- -----------------------------------------------------------------------------
-- 2. System Security Capabilities (Fixed keys to match schema: binary, type, mode)
-- -----------------------------------------------------------------------------
hl.permission({ binary = "/usr/bin/hyprlock", type = "screencopy", mode = "allow" })

-- Screenshot, Capture Engine & Desktop Portals Layer Validation
hl.permission({ binary = "/usr/bin/still", type = "screencopy", mode = "allow" })
hl.permission({ binary = "/usr/share/man/man1/still.1.gz", type = "screencopy", mode = "allow" })
hl.permission({ binary = "/usr/src/debug/still", type = "screencopy", mode = "allow" })
hl.permission({ binary = "/usr/bin/grim", type = "screencopy", mode = "allow" })
hl.permission({ binary = "/usr/share/man/man1/grim.1.gz", type = "screencopy", mode = "allow" })
hl.permission({ binary = "/usr/lib/xdg-desktop-portal-hyprland", type = "screencopy", mode = "allow" })
