-- OrkaOS colors. Placeholder until the Orka theme is designed (roadmap TODO):
-- Arch-blue accent on dark grey.
local theme = {
    accent          = "rgba(1793d1ee)",
    accent2         = "rgba(33ccffee)",
    inactive        = "rgba(595959aa)",
    shadow          = 0xee1a1a1a,
}
theme.active_border = { colors = { theme.accent, theme.accent2 }, angle = 45 }

ORKA_THEME = theme
return theme
