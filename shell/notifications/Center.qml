// The notification center: every kept notification, newest first, in a box
// under the bell (top right, on the focused monitor). Opened by the bell in
// the bar or SUPER + N; Escape or a click outside closes it. Header: do not
// disturb on/off and "Clear all". The cards work as popups do (click: the
// default action, buttons: other actions), plus a close button.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs
import qs.polkit

PanelWindow {
    id: window

    screen: Quickshell.screens.find(s => Hyprland.focusedMonitor && s.name === Hyprland.focusedMonitor.name) ?? Quickshell.screens[0]
    visible: Notifications.centerOpen

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    // Below the bar (its exclusive zone), so the bell still toggles it.
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "orka-notification-center"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: "transparent"

    // "5 min ago" stays current while it's open.
    property real now: Date.now()
    Timer {
        interval: 30000
        repeat: true
        triggeredOnStart: true
        running: window.visible
        onTriggered: window.now = Date.now()
    }

    onVisibleChanged: {
        if (!visible)
            return;
        CalendarState.open = false;   // both drop down under the bar
        Qt.callLater(() => box.forceActiveFocus());
    }

    // A click outside the box closes it.
    MouseArea {
        anchors.fill: parent
        onClicked: Notifications.centerOpen = false
    }

    Rectangle {
        id: box
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 8
        width: 420
        height: Math.min(header.implicitHeight + Math.max(list.contentHeight, 60) + 3 * 12 + 2 * border.width, parent.height * 0.8)
        color: Theme.background
        border.width: 2
        border.color: Theme.accent

        focus: true
        Keys.onEscapePressed: Notifications.centerOpen = false

        MouseArea {
            anchors.fill: parent   // clicks inside don't close it
        }

        RowLayout {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: "Notifications"
                color: Theme.foreground
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 2
                font.bold: true
            }
            DialogButton {
                text: (Notifications.dnd ? Theme.icons.dnd : Theme.icons.bell) + "  Do not disturb"
                primary: Notifications.dnd
                onClicked: Notifications.dnd = !Notifications.dnd
            }
            DialogButton {
                text: "Clear all"
                enabled: Notifications.history.length > 0
                onClicked: Notifications.clearAll()
            }
        }

        ListView {
            id: list
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            anchors.margins: 12
            clip: true
            spacing: 8
            boundsBehavior: Flickable.StopAtBounds
            model: Notifications.history

            delegate: NotificationCard {
                width: list.width
                inCenter: true
                now: window.now
            }
        }

        Text {
            anchors.centerIn: list
            visible: list.count === 0
            text: "No notifications"
            color: Theme.foreground
            opacity: 0.6
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
        }
    }
}
