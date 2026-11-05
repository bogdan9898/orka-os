-- Started once when Hyprland starts. uwsm already imports the environment
-- into systemd and runs XDG autostart entries (e.g. KDE Connect).
--
-- Not here yet, on purpose: bar, notifications, launcher, OSD, lock screen and
-- the polkit agent. Those will be OrkaOS's own Quickshell components.
local apps = require("orka.apps")

hl.on("hyprland.start", function()
    hl.exec_cmd(apps.run("hypridle"))
    hl.exec_cmd(apps.run("orka-wallpaper"))
end)
