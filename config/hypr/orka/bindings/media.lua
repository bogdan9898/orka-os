-- Volume and media keys (no on-screen display yet: the OSD will be a
-- Quickshell component).
local function bind(keys, cmd, description, opts)
    opts = opts or {}
    opts.description = description
    hl.bind(keys, hl.dsp.exec_cmd(cmd), opts)
end
local held = { locked = true, repeating = true }
local once = { locked = true }

bind("XF86AudioRaiseVolume",       "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+", "Volume up",   held)
bind("XF86AudioLowerVolume",       "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",      "Volume down", held)
bind("ALT + XF86AudioRaiseVolume", "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 1%+", "Volume up (fine)",   held)
bind("ALT + XF86AudioLowerVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-",      "Volume down (fine)", held)
bind("XF86AudioMute",              "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",     "Mute",            once)
bind("XF86AudioMicMute",           "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",   "Mute microphone", once)

bind("XF86AudioNext",  "playerctl next",       "Next track",     once)
bind("XF86AudioPrev",  "playerctl previous",   "Previous track", once)
bind("XF86AudioPlay",  "playerctl play-pause", "Play/pause",     once)
bind("XF86AudioPause", "playerctl play-pause", "Play/pause",     once)
