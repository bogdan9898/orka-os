-- Environment for apps started by Hyprland.

-- Mouse cursor: Bibata Modern Classic, size 24, unless settings.json has
-- .cursor.theme / .cursor.size (through orka/settings.lua). orka-settings
-- also sets it in a running session (hyprctl setcursor) and for GTK/KDE.
local cursor = require("orka.settings").cursor
hl.env("XCURSOR_THEME", cursor.theme or "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", tostring(cursor.size or 24))
hl.env("HYPRCURSOR_SIZE", tostring(cursor.size or 24))

-- Prefer Wayland everywhere, with X11 as fallback.
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
-- Qt apps take their style, colors and icons from qt6ct, which orka-settings
-- sets up from the current theme.
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.config({
    xwayland  = { force_zero_scaling = true },
    ecosystem = { no_update_news = true, no_donation_nag = true },
})
