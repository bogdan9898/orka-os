-- Window rules (based on Omarchy v3.8.4, adapted to OrkaOS's apps).

-- Ignore apps asking to be maximized; tiling decides the size.
hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })

-- XWayland drag-and-drop helper windows must not take focus.
hl.window_rule({
    name  = "xwayland-drag-fix",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

-- Slight transparency by default; media, browsers and VMs stay opaque.
hl.window_rule({ name = "opacity-default",  match = { class = ".*" }, opacity = "0.97 0.9" })
hl.window_rule({ name = "opacity-browsers", match = { class = "^([fF]irefox|zen|librewolf|chromium)$" }, opacity = "1.0 0.97" })
hl.window_rule({
    name    = "opacity-opaque",
    match   = { class = "^(mpv|imv|vlc|qemu|org.kde.filelight|libreoffice.*|soffice|gpu-screen-recorder.*)$" },
    opacity = "1 1",
})

-- Floating, centered windows: our TUIs (org.orka.*), small tools and dialogs.
local float_classes = table.concat({
    [[org\.orka\..*]], [[org\.gnome\.Calculator]], [[org\.gnome\.Evince]], [[com\.gabm\.satty]],
    "imv", "mpv", [[org\.pulseaudio\.pavucontrol]], "hyprland-run", [[org\.kde\.kdeconnect\.app]],
}, "|")
hl.window_rule({
    name   = "float-tools",
    match  = { class = "^(" .. float_classes .. ")$" },
    float  = true,
    center = true,
    size   = "875 600",
})
hl.window_rule({
    name   = "float-dialogs",
    match  = { title = "^(Open.*Files?|Open [Ff]older.*|Save.*Files?|Save.*As|Save|All Files|.*wants to (open|save).*|[Cc]hoose.*)$" },
    float  = true,
    center = true,
    size   = "875 600",
})

-- Picture-in-picture video: small, pinned, top right.
hl.window_rule({
    name              = "pip",
    match             = { title = "^(Picture.?in.?[Pp]icture)$" },
    float             = true,
    pin               = true,
    size              = "600 338",
    keep_aspect_ratio = true,
    border_size       = 0,
    opacity           = "1 1",
    move              = "(monitor_w-window_w-40) (monitor_h*0.04)",
})

-- Screen-sharing indicator windows go to a hidden workspace.
hl.window_rule({ name = "sharing-indicator", match = { title = ".*is sharing.*" }, workspace = "special silent" })
