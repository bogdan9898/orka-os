-- Universal copy/paste/cut: SUPER+C/V/X work in terminals and GUI apps alike.
local bind = require("orka.keys").section("Clipboard")

bind("SUPER + C", hl.dsp.send_shortcut({ mods = "CTRL",  key = "Insert" }), "Copy")
bind("SUPER + V", hl.dsp.send_shortcut({ mods = "SHIFT", key = "Insert" }), "Paste")
bind("SUPER + X", hl.dsp.send_shortcut({ mods = "CTRL",  key = "X" }),      "Cut")
