// An on/off switch: a track with a knob that slides to the right when on.
import QtQuick
import qs

Rectangle {
    id: root
    property bool checked: false
    signal toggled(bool checked)

    implicitWidth: 52
    implicitHeight: 28
    radius: height / 2
    color: checked ? Theme.accent : Qt.alpha(Theme.foreground, area.containsMouse ? 0.3 : 0.2)
    Behavior on color { ColorAnimation { duration: 150 } }

    Rectangle {
        width: parent.height - 6
        height: width
        radius: width / 2
        y: 3
        x: root.checked ? root.width - width - 3 : 3
        color: root.checked ? Theme.background : Theme.foreground
        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
