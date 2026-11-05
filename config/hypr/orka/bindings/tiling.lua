-- Window and workspace management (Omarchy v3.8.4 "tiling-v2" layout).
local function bind(keys, dispatcher, description, opts)
    opts = opts or {}
    opts.description = description
    hl.bind(keys, dispatcher, opts)
end

bind("SUPER + W",          hl.dsp.window.close(),                          "Close window")
bind("SUPER + J",          hl.dsp.layout("togglesplit"),                   "Toggle window split")
bind("SUPER + P",          hl.dsp.window.pseudo(),                         "Pseudo window")
bind("SUPER + T",          hl.dsp.window.float({ action = "toggle" }),     "Toggle floating/tiling")
bind("SUPER + F",          hl.dsp.window.fullscreen({ mode = "fullscreen" }), "Full screen")
bind("SUPER + ALT + F",    hl.dsp.window.fullscreen({ mode = "maximized" }),  "Full width")
bind("SUPER + O",          hl.dsp.window.pin(),                            "Pin floating window")

-- Focus, swap
for key, dir in pairs({ LEFT = "left", RIGHT = "right", UP = "up", DOWN = "down" }) do
    bind("SUPER + " .. key,         hl.dsp.focus({ direction = dir }),        "Focus " .. dir)
    bind("SUPER + SHIFT + " .. key, hl.dsp.window.swap({ direction = dir }),  "Swap window " .. dir)
    bind("SUPER + SHIFT + ALT + " .. key, hl.dsp.workspace.move({ monitor = dir:sub(1, 1) }), "Move workspace to monitor " .. dir)
    bind("SUPER + ALT + " .. key,   hl.dsp.window.move({ into_group = dir }), "Move window into group " .. dir)
end

-- Workspaces 1-10 (key 0 = 10); code:10..19 are the number row on any layout.
for i = 1, 10 do
    local key = "code:" .. (9 + i)
    bind("SUPER + " .. key,               hl.dsp.focus({ workspace = i }),                       "Workspace " .. i)
    bind("SUPER + SHIFT + " .. key,       hl.dsp.window.move({ workspace = i }),                 "Move window to workspace " .. i)
    bind("SUPER + SHIFT + ALT + " .. key, hl.dsp.window.move({ workspace = i, follow = false }), "Move window silently to workspace " .. i)
end

bind("SUPER + S",          hl.dsp.workspace.toggle_special("scratchpad"),                   "Toggle scratchpad")
bind("SUPER + ALT + S",    hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }), "Move window to scratchpad")
bind("SUPER + TAB",        hl.dsp.focus({ workspace = "e+1" }),      "Next workspace")
bind("SUPER + SHIFT + TAB",hl.dsp.focus({ workspace = "e-1" }),      "Previous workspace")
bind("SUPER + CTRL + TAB", hl.dsp.focus({ workspace = "previous" }), "Former workspace")
bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }),      "Next workspace")
bind("SUPER + mouse_up",   hl.dsp.focus({ workspace = "e-1" }),      "Previous workspace")

-- Cycle windows, monitors
bind("ALT + TAB",              hl.dsp.window.cycle_next(),                 "Focus next window")
bind("ALT + SHIFT + TAB",      hl.dsp.window.cycle_next({ next = false }),  "Focus previous window")
bind("CTRL + ALT + TAB",       hl.dsp.focus({ monitor = "+1" }),          "Focus next monitor")
bind("CTRL + ALT + SHIFT + TAB", hl.dsp.focus({ monitor = "-1" }),        "Focus previous monitor")

-- Resize with - and = (code:20, code:21)
bind("SUPER + code:20",         hl.dsp.window.resize({ x = -100, y = 0, relative = true }), "Shrink window width", { repeating = true })
bind("SUPER + code:21",         hl.dsp.window.resize({ x = 100,  y = 0, relative = true }), "Grow window width",   { repeating = true })
bind("SUPER + SHIFT + code:20", hl.dsp.window.resize({ x = 0, y = -100, relative = true }), "Shrink window height", { repeating = true })
bind("SUPER + SHIFT + code:21", hl.dsp.window.resize({ x = 0, y = 100,  relative = true }), "Grow window height",   { repeating = true })

-- Mouse: move and resize
bind("SUPER + mouse:272", hl.dsp.window.drag(),   "Move window",   { mouse = true })
bind("SUPER + mouse:273", hl.dsp.window.resize(), "Resize window", { mouse = true })

-- Groups (tabbed windows)
bind("SUPER + G",             hl.dsp.group.toggle(),                    "Toggle window grouping")
bind("SUPER + ALT + G",       hl.dsp.window.move({ out_of_group = true }), "Move window out of group")
bind("SUPER + ALT + TAB",     hl.dsp.group.next(),                      "Next window in group")
bind("SUPER + ALT + SHIFT + TAB", hl.dsp.group.prev(),                  "Previous window in group")
for i = 1, 5 do
    bind("SUPER + ALT + code:" .. (9 + i), hl.dsp.group.active({ index = i }), "Group window " .. i)
end
