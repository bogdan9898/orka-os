-- Universal copy/paste/cut: SUPER+C/V/X work in terminals and GUI apps alike.
hl.bind("SUPER + C", hl.dsp.send_shortcut({ mods = "CTRL",  key = "Insert" }), { description = "Copy" })
hl.bind("SUPER + V", hl.dsp.send_shortcut({ mods = "SHIFT", key = "Insert" }), { description = "Paste" })
hl.bind("SUPER + X", hl.dsp.send_shortcut({ mods = "CTRL",  key = "X" }),      { description = "Cut" })
