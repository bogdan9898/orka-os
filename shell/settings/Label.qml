// Text in a settings page: a group heading (`heading: true`) or normal text.
import QtQuick
import QtQuick.Layouts
import qs

Text {
    property bool heading: false
    property bool dim: false
    Layout.fillWidth: true
    color: heading ? Theme.accent : Theme.foreground
    opacity: dim ? 0.6 : 1
    font.family: Theme.font
    font.pixelSize: heading ? Theme.fontSize + 2 : Theme.fontSize
    font.bold: heading
    wrapMode: Text.Wrap
}
