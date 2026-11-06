// A flat button for shell dialogs.
import QtQuick
import qs

Rectangle {
    id: button
    property alias text: label.text
    property bool primary: false
    signal clicked

    implicitWidth: label.implicitWidth + 28
    implicitHeight: label.implicitHeight + 12
    opacity: enabled ? 1 : 0.5
    color: primary || area.containsMouse ? Theme.accent : "transparent"
    border.width: 1
    border.color: Theme.accent

    Text {
        id: label
        anchors.centerIn: parent
        color: Theme.foreground
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        font.bold: button.primary
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}
