// Orka Calculator. Python (main.py) provides `calc` (the calculator) and
// `theme` (the current OrkaOS theme's colors). Square corners, flat keys and
// JetBrains Mono, like the OrkaOS shell and Settings.
import QtQuick
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: win
    title: "Calculator"
    visible: true
    color: theme.bg

    readonly property string mode: calc.mode
    readonly property int mainWidth: mode === "standard" ? 380 : mode === "expert" ? 760 : 720
    readonly property int historyWidth: 240

    // A fixed size per mode (plus the history), so the window fits its keys.
    readonly property int fullWidth: mainWidth + (calc.historyOpen ? historyWidth : 0)
    readonly property int fullHeight: Math.ceil(content.implicitHeight)
    width: fullWidth
    height: fullHeight
    minimumWidth: fullWidth
    maximumWidth: fullWidth
    minimumHeight: fullHeight
    maximumHeight: fullHeight

    // Keyboard: digits, operators, Enter, Backspace, Escape; Ctrl+1/2/3
    // modes, Ctrl+H history, Ctrl+C/V copy and paste.
    Item {
        id: keys
        focus: true
        anchors.fill: parent
        Keys.onPressed: event => {
            if (calc.keyEvent(event.key, event.text, event.modifiers))
                event.accepted = true;
        }
    }

    RowLayout {
        id: content
        width: win.fullWidth
        spacing: 0

        ColumnLayout {
            Layout.preferredWidth: win.mainWidth
            Layout.alignment: Qt.AlignTop
            spacing: 0

            // Modes, and the switches on the right.
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 14
                Layout.bottomMargin: 0
                spacing: 8

                Segments {
                    name: "mode"
                    options: [{ label: "Standard", value: "standard" }, { label: "Expert", value: "expert" },
                              { label: "Programmer", value: "programmer" }]
                    current: win.mode
                    onPicked: value => calc.setMode(value)
                }
                Item { Layout.fillWidth: true }
                Text {
                    visible: calc.memorySet && win.mode !== "programmer"
                    text: "M"
                    color: theme.accent2
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    font.bold: true
                }
                Pill {
                    objectName: "angle"
                    visible: win.mode === "expert"
                    label: calc.degrees ? "DEG" : "RAD"
                    on: true
                    onActivated: calc.press("angle")
                }
                Pill {
                    objectName: "history"
                    label: String.fromCodePoint(0xF02DA) + " History"   // nf-md-history
                    outlined: false
                    on: calc.historyOpen
                    onActivated: calc.toggleHistory()
                }
            }

            // The display.
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: 18
                Layout.topMargin: 16
                Layout.bottomMargin: 8
                spacing: 2

                Text {
                    objectName: "last"
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: calc.lastText || " "
                    color: theme.dim
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    elide: Text.ElideLeft
                }
                Text {
                    id: main
                    objectName: "main"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    text: calc.mainText
                    color: theme.fg
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 44
                    font.bold: true
                    fontSizeMode: Text.HorizontalFit
                    minimumPixelSize: 16
                    elide: Text.ElideLeft
                }
                Text {
                    objectName: "preview"
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: win.mode === "programmer" && !calc.hasError
                          ? calc.base.toUpperCase() + " · " + (calc.signed ? "signed" : "unsigned") + " · " + calc.word + "-bit"
                          : (calc.previewText || " ")
                    color: calc.hasError ? theme.urgent : theme.accent2
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    elide: Text.ElideLeft
                }
            }

            // Memory (Standard and Expert).
            RowLayout {
                visible: win.mode !== "programmer"
                Layout.fillWidth: true
                Layout.leftMargin: 14
                Layout.rightMargin: 14
                Layout.bottomMargin: 8
                spacing: 4
                Repeater {
                    model: [{ id: "mc", label: "MC" }, { id: "mr", label: "MR" }, { id: "mplus", label: "M+" },
                            { id: "mminus", label: "M−" }, { id: "ms", label: "MS" }]
                    Rectangle {
                        id: mkey
                        required property var modelData
                        objectName: "key:" + modelData.id
                        Layout.fillWidth: true
                        implicitHeight: 26
                        color: ma.containsMouse ? theme.surface : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: mkey.modelData.label
                            color: ma.containsMouse ? theme.fg : theme.dim
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                        }
                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mkey.click()
                        }
                        function click() { calc.press(modelData.id); }
                    }
                }
            }

            // Programmer: the value in four bases, word size, signed, bits.
            ProgrammerPanel {
                visible: win.mode === "programmer"
                Layout.fillWidth: true
            }

            // The keys.
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 14
                Layout.topMargin: 0
                spacing: 6

                ExpertKeys {
                    visible: win.mode === "expert"
                    Layout.preferredWidth: 330
                    Layout.alignment: Qt.AlignTop
                }
                StandardKeys {
                    visible: win.mode !== "programmer"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                }
                ProgrammerKeys {
                    visible: win.mode === "programmer"
                    Layout.fillWidth: true
                }
            }
        }

        HistoryPanel {
            visible: calc.historyOpen
            Layout.preferredWidth: win.historyWidth
            Layout.fillHeight: true
        }
    }
}
