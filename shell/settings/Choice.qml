// A selectable button: one of several options (a row of these is a choice).
import QtQuick
import qs

Rectangle {
    id: root
    property alias text: label.text
    property bool selected: false
    signal clicked

    implicitWidth: label.implicitWidth + 24
    implicitHeight: label.implicitHeight + 12
    color: selected ? Theme.accent : area.containsMouse ? Qt.alpha(Theme.accent, 0.2) : "transparent"
    border.width: 1
    border.color: selected ? Theme.accent : Qt.alpha(Theme.foreground, 0.3)

    Text {
        id: label
        anchors.centerIn: parent
        color: root.selected ? Theme.background : Theme.foreground
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        font.bold: root.selected
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
