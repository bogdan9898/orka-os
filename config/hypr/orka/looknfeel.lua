-- Gaps, borders, blur and animations (based on Omarchy v3.8.4).
local theme = require("orka.theme")

hl.config({
    general = {
        gaps_in          = 5,
        gaps_out         = 10,
        border_size      = 2,
        col = {
            active_border   = theme.active_border,
            inactive_border = theme.inactive,
        },
        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding = 0,
        shadow = {
            enabled      = true,
            range        = 2,
            render_power = 3,
            color        = theme.shadow,
        },
        blur = {
            enabled    = true,
            size       = 2,
            passes     = 2,
            special    = true,
            brightness = 0.60,
            contrast   = 0.75,
        },
    },

    group = {
        col = {
            border_active          = theme.active_border,
            border_inactive        = theme.inactive,
            border_locked_active   = theme.active_border,
            border_locked_inactive = theme.inactive,
        },
        groupbar = {
            font_size        = 12,
            font_family      = "monospace",
            height           = 22,
            indicator_height = 0,
            gradients        = true,
        },
    },

    animations = { enabled = require("orka.settings").animations.enabled ~= false },

    dwindle   = { preserve_split = true, force_split = 2 },
    master    = { new_status = "master" },
    scrolling = { column_width = 0.49 },

    misc = {
        disable_hyprland_logo      = true,
        disable_splash_rendering   = true,
        disable_scale_notification = true,
        focus_on_activate          = true,
        anr_missed_pings           = 3,
        on_focus_under_fullscreen  = 1,
        key_press_enables_dpms     = true,
        mouse_move_enables_dpms    = true,
        vrr                        = 2,   -- variable refresh rate in fullscreen apps (FreeSync)
        -- A restarted OrkaOS shell may take over the lock after a crash
        -- (otherwise the session stays on Hyprland's "lock screen crashed" screen).
        allow_session_lock_restore = true,
    },

    cursor = {
        hide_on_key_press        = true,
        warp_on_change_workspace = 1,
    },

    binds = { hide_special_on_workspace_change = true },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}    } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}  } })

-- Animations: Settings → Animations (settings.json .animations, through
-- orka/settings.lua). speed multiplies every duration (Hyprland counts in
-- tenths of a second: 4.1 = 0.41 s), windows is the open/close style,
-- workspaces the workspace switch, moves = moving/resizing windows.
local anim = require("orka.settings").animations
local factor = tonumber(anim.speed) or 1
local window_styles = { popin = "popin 87%", slide = "slide", gnomed = "gnomed", fade = "popin 100%" }
local window_style = window_styles[anim.windows] or window_styles.popin
local workspace_styles = { slide = "slide", slidevert = "slidevert", fade = "fade", slidefade = "slidefade 20%" }
local workspace_style = workspace_styles[anim.workspaces]   -- nil = off (instant)

local function animate(leaf, speed, bezier, style)
    hl.animation({ leaf = leaf, enabled = true, speed = speed * factor, bezier = bezier, style = style })
end

animate("global",           10,   "default")
animate("border",           5.39, "easeOutQuint")
animate("windows",          3.79, "easeOutQuint")
animate("windowsIn",        4.1,  "easeOutQuint", window_style)
animate("windowsOut",       1.49, "linear",       window_style)
if anim.moves == false then
    hl.animation({ leaf = "windowsMove", enabled = false })
else
    animate("windowsMove",  3.79, "easeOutQuint")
end
animate("fadeIn",           1.73, "almostLinear")
animate("fadeOut",          1.46, "almostLinear")
animate("fade",             3.03, "quick")
animate("layers",           3.81, "easeOutQuint")
animate("layersIn",         4,    "easeOutQuint", "fade")
animate("layersOut",        1.5,  "linear",       "fade")
animate("fadeLayersIn",     1.79, "almostLinear")
animate("fadeLayersOut",    1.39, "almostLinear")
if workspace_style then
    animate("workspaces",   3.5,  "easeOutQuint", workspace_style)
else
    hl.animation({ leaf = "workspaces", enabled = false })
end
animate("specialWorkspace", 3,    "easeOutQuint", "slidevert")
