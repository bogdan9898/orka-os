// One calculator key. kind: num (digits), fn (functions), op (operators,
// teal), clear (AC and ⌫, red), eq (=, filled with the accent), sci (the
// outlined Expert keys). Sends keyId to Python (calc.press).
import QtQuick

Rectangle {
    id: key
    property string keyId
    property string label
    property string kind: "num"
    property bool on: false          // a switch that's on (2nd)
    readonly property bool usable: calc.disabledKeys.indexOf(keyId) < 0
    signal activated

    objectName: "key:" + keyId
    implicitWidth: 56
    implicitHeight: kind === "sci" ? 50 : 52
    opacity: usable ? 1 : 0.25

    readonly property color base: kind === "eq" ? theme.accent
                                : kind === "sci" ? "transparent"
                                : kind === "num" ? theme.key : theme.keyop
    color: !usable ? base
         : area.pressed ? (kind === "eq" ? Qt.lighter(theme.accent, 1.15) : Qt.tint(base, Qt.alpha(theme.accent, 0.4)))
         : area.containsMouse ? (kind === "eq" ? Qt.tint(theme.accent, Qt.alpha(theme.fg, 0.15)) : Qt.tint(base, Qt.alpha(theme.accent, 0.22)))
         : base
    border.width: kind === "sci" ? 1 : 0
    border.color: on || (area.containsMouse && usable) ? theme.accent : theme.line

    Text {
        anchors.centerIn: parent
        text: key.label
        color: key.kind === "eq" ? theme.bg
             : key.kind === "op" ? theme.accent2
             : key.kind === "clear" ? theme.urgent
             : key.on ? theme.accent : theme.fg
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: key.kind === "op" ? 20 : key.kind === "eq" ? 22 : key.kind === "num" ? 17 : 14
        font.bold: key.kind === "eq"
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: key.usable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: key.click()
    }

    function click() {
        if (!usable)
            return;
        if (keyId !== "")
            calc.press(keyId);
        activated();
    }
}
