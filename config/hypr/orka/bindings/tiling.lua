-- Window and workspace management (Omarchy v3.8.4 "tiling-v2" layout).
local section = require("orka.keys").section
local bind = section("Windows")
local workspace = section("Workspaces")
local group = section("Groups (tabs)")

-- SUPER + W closes an OrkaOS panel (cheat sheet, launcher, settings,
-- calendar) when one is open: they take the keyboard, so otherwise the
-- window hidden under the panel would close instead. Else the window.
local panels = { ["orka-cheatsheet"] = "cheatsheet", ["orka-launcher"] = "launcher", ["orka-settings"] = "settings", ["orka-calendar"] = "calendar" }
local function close_panel_or_window()
    for _, layer in ipairs(hl.get_layers()) do
        local target = panels[layer.namespace]
        if target and layer.mapped then
            hl.exec_cmd("qs -p /usr/share/orka/shell ipc call " .. target .. " close")
            return
        end
    end
    hl.dispatch(hl.dsp.window.close())
end
bind("SUPER + W",         close_panel_or_window,                          "Close window (or open panel)")
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
    workspace("SUPER + SHIFT + ALT + " .. key, hl.dsp.workspace.move({ monitor = dir:sub(1, 1) }), "Move workspace to monitor " .. dir)
    group("SUPER + ALT + " .. key,  hl.dsp.window.move({ into_group = dir }), "Move window into group " .. dir)
end

-- Workspaces 1-10 (key 0 = 10); code:10..19 are the number row on any layout.
for i = 1, 10 do
    local key = "code:" .. (9 + i)
    workspace("SUPER + " .. key,               hl.dsp.focus({ workspace = i }),                       "Workspace " .. i)
    workspace("SUPER + SHIFT + " .. key,       hl.dsp.window.move({ workspace = i }),                 "Move window to workspace " .. i)
    workspace("SUPER + SHIFT + ALT + " .. key, hl.dsp.window.move({ workspace = i, follow = false }), "Move window silently to workspace " .. i)
end

workspace("SUPER + S",          hl.dsp.workspace.toggle_special("scratchpad"),                   "Toggle scratchpad")
workspace("SUPER + ALT + S",    hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }), "Move window to scratchpad")
workspace("SUPER + TAB",        hl.dsp.focus({ workspace = "e+1" }),      "Next workspace")
workspace("SUPER + SHIFT + TAB",hl.dsp.focus({ workspace = "e-1" }),      "Previous workspace")
workspace("SUPER + CTRL + TAB", hl.dsp.focus({ workspace = "previous" }), "Former workspace")
workspace("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }),      "Next workspace")
workspace("SUPER + mouse_up",   hl.dsp.focus({ workspace = "e-1" }),      "Previous workspace")

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
group("SUPER + G",             hl.dsp.group.toggle(),                    "Toggle window grouping")
group("SUPER + ALT + G",       hl.dsp.window.move({ out_of_group = true }), "Move window out of group")
group("SUPER + ALT + TAB",     hl.dsp.group.next(),                      "Next window in group")
group("SUPER + ALT + SHIFT + TAB", hl.dsp.group.prev(),                  "Previous window in group")
for i = 1, 5 do
    group("SUPER + ALT + code:" .. (9 + i), hl.dsp.group.active({ index = i }), "Group window " .. i)
end
