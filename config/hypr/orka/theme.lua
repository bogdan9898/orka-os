-- OrkaOS colors for Hyprland: the current theme's (Settings → Theme, through
-- orka/settings.lua), else these defaults.
local colors = require("orka.settings").colors
local theme = {
    accent          = colors.accent   or "rgba(1793d1ee)",
    accent2         = colors.accent2  or "rgba(33ccffee)",
    inactive        = colors.inactive or "rgba(595959aa)",
    shadow          = 0xee1a1a1a,
}
theme.active_border = { colors = { theme.accent, theme.accent2 }, angle = 45 }

ORKA_THEME = theme
return theme
