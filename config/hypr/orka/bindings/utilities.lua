-- Launcher, screenshots, system actions.
local apps = require("orka.apps")
local function bind(keys, cmd, description)
    hl.bind(keys, hl.dsp.exec_cmd(cmd), { description = description })
end

-- App launcher (the OrkaOS shell); also runs a typed command.
bind("SUPER + SPACE",          "qs -p /usr/share/orka/shell ipc call launcher toggle", "App launcher")
bind("SUPER + K",              apps.tui("orka-keybindings", "keybindings"), "Show key bindings")

-- Screenshots, recording, color picker, OCR
bind("PRINT",                  "orka-screenshot region",             "Screenshot (region, edit)")
bind("SHIFT + PRINT",          "orka-screenshot screen",             "Screenshot (screen, edit)")
bind("ALT + PRINT",            "orka-screenrecord",                  "Start/stop screen recording")
bind("SUPER + PRINT",          "pkill hyprpicker || hyprpicker -a",  "Color picker")
bind("SUPER + CTRL + PRINT",   "orka-screenshot text",               "Copy text from screen region (OCR)")

-- Notifications (the OrkaOS shell)
bind("SUPER + comma",               "orka-notifications dismiss",     "Dismiss last notification")
bind("SUPER + SHIFT + comma",       "orka-notifications dismiss-all", "Dismiss all notifications")
bind("SUPER + ALT + comma",         "orka-notifications invoke",      "Invoke last notification")
bind("SUPER + SHIFT + ALT + comma", "orka-notifications restore",     "Restore last notification")
bind("SUPER + CTRL + comma",        "orka-notifications dnd",         "Toggle do not disturb")

-- Night light, zoom
bind("SUPER + CTRL + N",       "orka-nightlight",                    "Toggle night light")
bind("SUPER + CTRL + Z",       "hyprctl eval 'hl.config({ cursor = { zoom_factor = 2 } })'", "Zoom in")
bind("SUPER + CTRL + ALT + Z", "hyprctl eval 'hl.config({ cursor = { zoom_factor = 1 } })'", "Reset zoom")

-- Leave the session. Deliberately awkward to press: there's no lock screen
-- or confirmation dialog yet (both are planned Quickshell components).
hl.bind("SUPER + CTRL + ALT + ESCAPE", hl.dsp.exec_cmd("uwsm stop"), { description = "Log out" })
