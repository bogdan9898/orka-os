-- Launcher, screenshots, notifications, system actions.
local apps = require("orka.apps")
local section = require("orka.keys").section
local system = section("System")
local capture = section("Screenshots & recording")
local notify = section("Notifications")

-- The OrkaOS shell: launcher (also runs a typed command), cheat sheet.
system("SUPER + SPACE",          "qs -p /usr/share/orka/shell ipc call launcher toggle", "App launcher")
system("SUPER + K",              "qs -p /usr/share/orka/shell ipc call cheatsheet toggle", "Keyboard shortcuts (cheat sheet)")
system("SUPER + SHIFT + K",      apps.tui("orka-keybindings", "keybindings"), "Search key bindings (terminal)")
system("SUPER + ALT + SPACE",    "qs -p /usr/share/orka/shell ipc call settings toggle", "Settings")

-- Screenshots, recording, color picker, OCR
capture("PRINT",                  "orka-screenshot region",             "Screenshot (region, edit)")
capture("SHIFT + PRINT",          "orka-screenshot screen",             "Screenshot (screen, edit)")
capture("ALT + PRINT",            "orka-screenrecord",                  "Start/stop screen recording")
capture("SUPER + PRINT",          "pkill hyprpicker || hyprpicker -a",  "Color picker")
capture("SUPER + CTRL + PRINT",   "orka-screenshot text",               "Copy text from screen region (OCR)")

-- Notifications (the OrkaOS shell)
notify("SUPER + comma",               "orka-notifications dismiss",     "Dismiss last notification")
notify("SUPER + SHIFT + comma",       "orka-notifications dismiss-all", "Dismiss all notifications")
notify("SUPER + ALT + comma",         "orka-notifications invoke",      "Invoke last notification")
notify("SUPER + SHIFT + ALT + comma", "orka-notifications restore",     "Restore last notification")
notify("SUPER + CTRL + comma",        "orka-notifications dnd",         "Toggle do not disturb")

-- Caps Lock / Num Lock state on the OSD. Passed through (the keys still do
-- their job), with any modifiers, and without a description so they stay
-- out of the cheat sheet.
for key, which in pairs({ Caps_Lock = "caps", Num_Lock = "num" }) do
    hl.bind(key, hl.dsp.exec_cmd("orka-osd keylock " .. which),
        { non_consuming = true, ignore_mods = true, locked = true })
end

-- Night light, zoom
system("SUPER + CTRL + N",       "orka-nightlight",                    "Toggle night light")
system("SUPER + CTRL + Z",       "hyprctl eval 'hl.config({ cursor = { zoom_factor = 2 } })'", "Zoom in")
system("SUPER + CTRL + ALT + Z", "hyprctl eval 'hl.config({ cursor = { zoom_factor = 1 } })'", "Reset zoom")

-- Lock, leave the session. Logging out is deliberately awkward to press:
-- there's no confirmation dialog yet.
system("SUPER + CTRL + L",       "orka-lock",                          "Lock the screen")
system("SUPER + CTRL + ALT + ESCAPE", "uwsm stop",                     "Log out")
