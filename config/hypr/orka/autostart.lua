-- Started once when Hyprland starts. uwsm already imports the environment
-- into systemd and runs XDG autostart entries (e.g. KDE Connect).
--
-- The OrkaOS shell (bar, notifications, launcher, lock screen...) is not
-- started here: it's the systemd user service orka-shell.service, started
-- with the session by uwsm and restarted if it crashes.
local apps = require("orka.apps")

hl.on("hyprland.start", function()
    hl.exec_cmd(apps.run("hypridle"))
    hl.exec_cmd(apps.run("orka-wallpaper"))
    hl.exec_cmd("orka-settings apply nightlight")   -- night light, if it was on
end)
