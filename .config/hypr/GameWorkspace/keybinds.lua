-- ~/Larke-shell/.config/hypr/GameWorkspace/keybinds.lua

-- Clear and remap the global gaming toggle launcher hook
hl.unbind("SUPER + G")
hl.bind("SUPER + G", hl.dsp.exec_cmd(scripts .. "/gametoggle.sh " .. main_monitor))

-- Map your dynamic backfilling game registration script
hl.bind("SUPER + ALT + G", hl.dsp.exec_cmd(scripts .. "/add-and-move-game.sh"))

-- Clear default close actions and route them through your custom force-kill manager
hl.unbind("SUPER + Q")
hl.bind("SUPER + Q", hl.dsp.exec_cmd(scripts .. "/close-window.sh"))
