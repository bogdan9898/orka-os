//@ pragma UseQApplication
// OrkaOS desktop shell (Quickshell). Installed to /usr/share/orka/shell and
// started by Hyprland (orka/autostart.lua) with `qs -p /usr/share/orka/shell`.
// Saving a file reloads the shell. So far: the bar (one per monitor),
// notifications (Notifications.qml, popups on the focused monitor), the
// polkit agent (admin password dialog), the app launcher, the lock screen and
// idle handling. Runs as the systemd user service orka-shell.service, which
// restarts it if it crashes. The login screen is greeter.qml.
//
// UseQApplication: system tray menus are Qt widget menus and need it.
import QtQuick
import Quickshell
import qs.bar
import qs.cheatsheet
import qs.launcher
import qs.lock
import qs.notifications
import qs.polkit

ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar {}
    }

    Popups {}
    PolkitDialog {}
    Launcher {}
    CheatSheet {}
    Lock {}
    Idle {}
}
