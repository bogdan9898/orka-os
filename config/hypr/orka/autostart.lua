-- Started once when Hyprland starts. uwsm already imports the environment
-- into systemd and runs XDG autostart entries (e.g. KDE Connect).
--
-- The OrkaOS shell (Quickshell, /usr/share/orka/shell) has the bar so far.
-- Still to come, as its own components: notifications, launcher, OSD, lock
-- screen and the polkit agent.
local apps = require("orka.apps")

hl.on("hyprland.start", function()
    hl.exec_cmd(apps.run("hypridle"))
    hl.exec_cmd(apps.run("orka-wallpaper"))
    hl.exec_cmd(apps.run("qs -p /usr/share/orka/shell"))
end)
