-- Default applications, used by the key bindings. Override any of them in
-- ~/.config/hypr/hyprland.lua *before* require("orka"), e.g.
--   ORKA_APPS = { browser = "chromium" }
local apps = {
    terminal    = "ghostty",
    browser     = "firefox",
    private     = "firefox --private-window",
    files       = "dolphin",
    editor      = "subl",
    calculator  = "orka-calculator",
}
for k, v in pairs(ORKA_APPS or {}) do apps[k] = v end

-- Launch through uwsm, so every app runs in its own systemd scope.
function apps.run(cmd) return "uwsm app -- " .. cmd end

-- A terminal program in its own (floating) Ghostty window, e.g. tui("btop").
function apps.tui(cmd, id)
    id = id or cmd:match("^(%S+)")
    return apps.run(string.format("%s --class=org.orka.%s -e %s", apps.terminal, id, cmd))
end

return apps
