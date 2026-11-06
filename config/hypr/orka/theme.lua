-- OrkaOS colors for Hyprland: the current theme's (Settings → Theme, through
-- orka/settings.lua), else these defaults.
local colors = require("orka.settings").colors
local theme = {
    accent          = colors.accent   or "rgba(3fa7d6ee)",
    accent2         = colors.accent2  or "rgba(7fd1c7ee)",
    inactive        = colors.inactive or "rgba(2e3d4daa)",
    shadow          = 0xee0d1620,
}
theme.active_border = { colors = { theme.accent, theme.accent2 }, angle = 45 }

ORKA_THEME = theme
return theme
