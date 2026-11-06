// A settings page: title, a short description, then the page's content
// (scrolls when it's taller than the window).
import QtQuick
import QtQuick.Layouts
import qs

Flickable {
    id: root
    property string title: ""
    property string description: ""
    default property alias content: body.data

    contentWidth: width
    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
        id: column
        width: root.width
        spacing: 18

        ColumnLayout {
            spacing: 4
            Text {
                text: root.title
                color: Theme.foreground
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 8
                font.bold: true
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.description
                color: Theme.foreground
                opacity: 0.6
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                wrapMode: Text.Wrap
            }
        }

        ColumnLayout {
            id: body
            Layout.fillWidth: true
            spacing: 18
        }
    }
}
