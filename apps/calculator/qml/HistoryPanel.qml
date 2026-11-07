// History (↺ History or Ctrl+H): the calculations of this mode, newest
// first. Click one to use its result.
import QtQuick
import QtQuick.Layouts

Rectangle {
    color: "transparent"

    Rectangle {   // the line between keys and history
        width: 1
        height: parent.height
        color: theme.line
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 1
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 14
            Layout.bottomMargin: 6
            Text {
                Layout.fillWidth: true
                text: "History"
                color: theme.dim
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
            }
            Pill {
                objectName: "clearHistory"
                visible: calc.history.length > 0
                label: "Clear"
                outlined: false
                onActivated: calc.clearHistory()
            }
        }

        Text {
            visible: calc.history.length === 0
            Layout.fillWidth: true
            Layout.margins: 14
            text: "No calculations yet."
            color: theme.dim
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            wrapMode: Text.Wrap
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: calc.history
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                id: item
                required property var modelData
                required property int index
                objectName: "history:" + index
                width: list.width
                height: col.implicitHeight + 16
                color: ha.containsMouse ? theme.surface : "transparent"
                Column {
                    id: col
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 28
                    spacing: 2
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignRight
                        text: item.modelData.expr + " ="
                        color: theme.dim
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        elide: Text.ElideLeft
                    }
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignRight
                        text: item.modelData.result
                        color: theme.fg
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        elide: Text.ElideLeft
                    }
                }
                MouseArea {
                    id: ha
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: item.click()
                }
                function click() { calc.useHistory(index); }
            }
        }
    }
}
