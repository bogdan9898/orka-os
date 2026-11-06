//@ pragma UseQApplication
// OrkaOS desktop shell (Quickshell). Installed to /usr/share/orka/shell and
// started by Hyprland (orka/autostart.lua) with `qs -p /usr/share/orka/shell`.
// Saving a file reloads the shell. So far: the bar (one per monitor) and
// notifications (Notifications.qml, popups on the focused monitor).
//
// UseQApplication: system tray menus are Qt widget menus and need it.
import QtQuick
import Quickshell
import qs.bar
import qs.notifications

ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar {}
    }

    Popups {}
}
