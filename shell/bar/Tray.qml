// System tray (StatusNotifierItem apps, e.g. KDE Connect). Click: the app's
// main action (or its menu, if that's all it has), right click: menu,
// middle click: secondary action.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

RowLayout {
    id: root
    required property var window   // the bar window, menus open relative to it
    spacing: 12

    Repeater {
        model: SystemTray.items

        MouseArea {
            id: area
            required property SystemTrayItem modelData
            implicitWidth: 14
            implicitHeight: 14
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
                anchors.fill: parent
                source: area.modelData.icon
            }
        }
    }
}
