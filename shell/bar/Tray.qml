// System tray (StatusNotifierItem apps, e.g. KDE Connect). Click: the app's
// main action (or its menu, if that's all it has), right click: menu,
// middle click: secondary action.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs

RowLayout {
    id: root
    required property var window   // the bar window, menus open relative to it
    spacing: 12

    Repeater {
        model: SystemTray.items

        MouseArea {
            id: area
            required property SystemTrayItem modelData
            // Hover: grows to the left and shows the app's own tooltip (else
            // its name) before the icon, like BarIcon.
            readonly property string tooltip: modelData.tooltipTitle || modelData.title || modelData.id
            property real expand: 0
            Behavior on expand {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }
            Timer {
                id: expandTimer
                interval: 400   // as BarIcon: a quick point-and-click never expands
                onTriggered: area.expand = 1
            }
            implicitWidth: 14 + Math.round((tipLabel.implicitWidth + 6) * expand)
            implicitHeight: 14
            hoverEnabled: true
            onEntered: expandTimer.restart()
            onExited: {
                expandTimer.stop();
                area.expand = 0;
            }
            onPressed: expandTimer.stop()

            Item {
                visible: area.expand > 0
                anchors.left: parent.left
                anchors.right: icon.left
                height: parent.height
                clip: true
                Text {
                    id: tipLabel
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: area.tooltip
                    color: Theme.foreground
                    opacity: area.expand
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                }
            }
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor

            function showMenu() {
                const p = area.mapToItem(null, 0, area.height + 6);
                modelData.display(root.window, p.x, p.y);
            }

            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton)
                    modelData.secondaryActivate();
                else if (mouse.button === Qt.RightButton || modelData.onlyMenu)
                    modelData.hasMenu && showMenu();
                else
                    modelData.activate();
            }
            onWheel: event => modelData.scroll(event.angleDelta.y, false)

            IconImage {
                id: icon
                anchors.right: parent.right
                width: 14
                height: 14
                source: area.modelData.icon
            }
        }
    }
}
