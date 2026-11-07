// A row of joined buttons, one of them selected (modes, word size).
// options: [{ label, value }]
import QtQuick

Row {
    id: seg
    property var options: []
    property var current
    property int fontSize: 12
    property string name: ""          // objectName prefix for tests
    signal picked(var value)

    spacing: -1

    Repeater {
        model: seg.options
        Rectangle {
            id: b
            required property var modelData
            readonly property bool selected: seg.current === modelData.value
            objectName: seg.name + ":" + modelData.value
            implicitWidth: t.implicitWidth + 22
            implicitHeight: t.implicitHeight + 10
            z: selected ? 1 : 0
            color: selected ? theme.accent : a.containsMouse ? Qt.alpha(theme.accent, 0.2) : "transparent"
            border.width: 1
            border.color: selected ? theme.accent : theme.line

            Text {
                id: t
                anchors.centerIn: parent
                text: b.modelData.label
                color: b.selected ? theme.bg : theme.fg
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: seg.fontSize
                font.bold: b.selected
            }
            MouseArea {
                id: a
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: b.click()
            }
            function click() { seg.picked(b.modelData.value); }
        }
    }
}
