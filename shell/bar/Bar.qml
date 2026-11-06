// The bar on one monitor: menu and workspaces on the left, clock in the
// middle, tray and status icons on the right. Reserves its height, so
// windows tile below it.
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

PanelWindow {
    id: bar
    required property ShellScreen modelData
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    color: Theme.background

    RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        BarIcon {
            text: Theme.icons.logo
            // Stand-ins until the Orka menu and launcher exist.
            onClicked: Apps.run(["hyprland-run"])
            onRightClicked: Apps.run([Apps.terminal])
        }
        Workspaces {
            screen: bar.screen
        }
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 10

        Clock {}
        Recording {}
    }

    RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 16

        Tray {
            window: bar
        }
        BluetoothStatus {}
        NetworkStatus {}
        Volume {}
        BarIcon {
            text: Theme.icons.cpu
            onClicked: Apps.tui("btop")
        }
    }
}
