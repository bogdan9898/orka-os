// A small outlined switch (DEG/RAD, Signed/Unsigned, History).
import QtQuick

Rectangle {
    id: pill
    property string label
    property bool on: false
    property bool outlined: true
    signal activated

    implicitWidth: t.implicitWidth + 16
    implicitHeight: t.implicitHeight + 8
    color: a.containsMouse ? Qt.alpha(theme.accent, 0.12) : "transparent"
    border.width: outlined || a.containsMouse ? 1 : 0
    border.color: on ? theme.accent2 : theme.line

    Text {
        id: t
        anchors.centerIn: parent
        text: pill.label
        color: pill.on ? theme.accent2 : a.containsMouse ? theme.fg : theme.dim
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 11
    }
    MouseArea {
        id: a
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: pill.activated()
    }
    function click() { activated(); }
}
