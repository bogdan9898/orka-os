// Programmer: the value in HEX, DEC, OCT and BIN (click one to type in that
// base), the word size, signed/unsigned, and the 64 bits (click to flip;
// bits outside the word size are greyed out).
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    spacing: 10

    // The four bases.
    Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: 14
        Layout.rightMargin: 14
        implicitHeight: rows.implicitHeight + 2
        color: "transparent"
        border.width: 1
        border.color: theme.line

        Column {
            id: rows
            x: 1
            y: 1
            width: parent.width - 2
            Repeater {
                model: ["hex", "dec", "oct", "bin"]
                Rectangle {
                    id: row
                    required property string modelData
                    required property int index
                    readonly property bool selected: calc.base === modelData
                    objectName: "base:" + modelData
                    width: rows.width
                    height: 32
                    color: selected ? Qt.alpha(theme.accent, 0.14) : ra.containsMouse ? theme.surface : "transparent"

                    Rectangle {   // the selected base's marker
                        visible: row.selected
                        width: 3
                        height: parent.height
                        color: theme.accent
                    }
                    Rectangle {
                        visible: row.index > 0
                        width: parent.width
                        height: 1
                        color: Qt.alpha(theme.fg, 0.08)
                    }
                    Text {
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 36
                        text: row.modelData.toUpperCase()
                        color: row.selected ? theme.accent : theme.dim
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                    }
                    Text {
                        objectName: "baseText:" + row.modelData
                        x: 56
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 68
                        text: calc.baseTexts[row.modelData] || "0"
                        color: theme.fg
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: row.modelData === "bin" && calc.word === 64 ? 12 : 14
                        elide: Text.ElideLeft
                    }
                    MouseArea {
                        id: ra
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: row.click()
                    }
                    function click() { calc.setBase(modelData); }
                }
            }
        }
    }

    // Word size and sign.
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 14
        Layout.rightMargin: 14
        spacing: 8
        Text {
            text: "Word"
            color: theme.dim
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
        }
        Segments {
            name: "word"
            fontSize: 11
            options: [{ label: "QWORD", value: 64 }, { label: "DWORD", value: 32 },
                      { label: "WORD", value: 16 }, { label: "BYTE", value: 8 }]
            current: calc.word
            onPicked: value => calc.setWord(value)
        }
        Item { Layout.fillWidth: true }
        Pill {
            objectName: "signed"
            label: calc.signed ? "Signed" : "Unsigned"
            on: calc.signed
            onActivated: calc.toggleSigned()
        }
    }

    // The bits: 63…48 | 47…32 on the first line, 31…16 | 15…0 on the second.
    GridLayout {
        Layout.leftMargin: 14
        Layout.rightMargin: 14
        Layout.bottomMargin: 10
        Layout.alignment: Qt.AlignHCenter
        columns: 2
        columnSpacing: 22
        rowSpacing: 6

        Repeater {
            model: [63, 47, 31, 15]
            Column {
                id: block
                required property int modelData
                spacing: 2
                Row {
                    spacing: 9
                    Repeater {
                        model: 4
                        Row {
                            id: nibble
                            required property int index
                            spacing: 2
                            Repeater {
                                model: 4
                                Rectangle {
                                    id: bit
                                    required property int index
                                    readonly property int n: block.modelData - nibble.index * 4 - index
                                    readonly property bool usable: n < calc.word
                                    readonly property bool one: usable && calc.bits[n] === 1
                                    objectName: "bit:" + n
                                    width: 15
                                    height: 22
                                    opacity: usable ? 1 : 0.18
                                    color: one ? theme.accent2 : "transparent"
                                    border.width: ba.containsMouse && usable ? 1 : 0
                                    border.color: theme.accent
                                    Text {
                                        anchors.centerIn: parent
                                        text: bit.one ? "1" : "0"
                                        color: bit.one ? theme.bg : theme.dim
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                        font.bold: bit.one
                                    }
                                    MouseArea {
                                        id: ba
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: bit.usable ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: bit.click()
                                    }
                                    function click() { if (usable) calc.flipBit(n); }
                                }
                            }
                        }
                    }
                }
                Item {
                    width: parent.width
                    height: 11
                    Text {
                        text: block.modelData
                        color: theme.dim
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 9
                    }
                    Text {
                        anchors.right: parent.right
                        text: block.modelData - 15
                        color: theme.dim
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 9
                    }
                }
            }
        }
    }
}
