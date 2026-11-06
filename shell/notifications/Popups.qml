// Notification popups: top right, under the bar, on the focused monitor.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs

PanelWindow {
    id: window

    screen: Quickshell.screens.find(s => Hyprland.focusedMonitor && s.name === Hyprland.focusedMonitor.name) ?? Quickshell.screens[0]
    visible: Notifications.popups.length > 0

    anchors {
        top: true
        right: true
    }
    margins {
        top: 8
        right: 8
    }
    // Keep clear of the bar (its exclusive zone), but don't reserve space.
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "orka-notifications"

    implicitWidth: 380
    implicitHeight: Math.max(1, column.implicitHeight)
    color: "transparent"

    Column {
        id: column
        width: parent.width
        spacing: 8

        Repeater {
            model: Notifications.popups

            NotificationCard {
                width: column.width
            }
        }
    }
}
