// Mouse cursor: pick one of the installed cursor themes (/usr/share/icons and
// your own in ~/.local/share/icons) and a size (cursor.theme / cursor.size,
// applied by orka-settings: Hyprland, GTK, KDE, X11 apps).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs

Page {
    id: page
    title: "Mouse cursor"
    description: "Add cursor themes by putting their folder (the one with a \"cursors\" folder inside, e.g. from a downloaded archive) into ~/.local/share/icons; they show up here."

    readonly property string userDir: Quickshell.env("HOME") + "/.local/share/icons"
    readonly property var sizes: [
        { label: "Normal", size: 24 }, { label: "Large", size: 32 },
        { label: "Larger", size: 40 }, { label: "Huge", size: 48 }
    ]
    property var cursors: []

    onVisibleChanged: {
        if (visible)
            list.running = true;
    }

    // Lists the themes and makes their preview images (cached).
    Process {
        id: list
        running: true
        command: ["orka-settings", "cursors"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    page.cursors = JSON.parse(text);
                } catch (e) {
                    page.cursors = [];
                }
            }
        }
    }

    Label {
        heading: true
        text: Theme.icons.cursor + "  Size"
    }
    Flow {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: page.sizes
            Choice {
                required property var modelData
                text: modelData.label + " (" + modelData.size + ")"
                selected: Settings.cursorSize === modelData.size
                onClicked: Settings.set(".cursor.size", modelData.size)
            }
        }
    }

    Label {
        heading: true
        text: Theme.icons.palette + "  Theme"
    }
    Flow {
        Layout.fillWidth: true
        spacing: 14

        Repeater {
            model: page.cursors

            Rectangle {
                id: card
                required property var modelData
                readonly property bool current: modelData.id === Settings.cursorTheme
                width: 224
                height: 116
                color: cardArea.containsMouse && !current ? Qt.alpha(Theme.accent, 0.12) : Qt.alpha(Theme.foreground, 0.04)
                border.width: current ? 3 : 1
                border.color: current ? Theme.accent : Qt.alpha(Theme.foreground, 0.3)

                // Arrow, hand, text and busy cursor.
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 12
                    spacing: 10
                    Repeater {
                        model: ["arrow", "hand", "text", "busy"]
                        Image {
                            required property string modelData
                            width: 40
                            height: 40
                            source: "file://" + card.modelData.previews + "/" + modelData + ".png"
                            sourceSize: Qt.size(48, 48)
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            cache: false
                        }
                    }
                }
                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 10
                    text: card.modelData.name.replace(/[-_]/g, " ") + (card.modelData.user ? " · yours" : "") + (card.current ? "  " + Theme.icons.check : "")
                    color: Theme.foreground
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    font.bold: card.current
                    elide: Text.ElideRight
                }
                MouseArea {
                    id: cardArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Settings.set(".cursor.theme", card.modelData.id)
                }
            }
        }
    }

    RowLayout {
        spacing: 8
        Choice {
            text: Theme.icons.folder + "  Open my cursors folder"
            onClicked: Quickshell.execDetached(["sh", "-c", "mkdir -p \"$1\" && xdg-open \"$1\"", "sh", page.userDir])
        }
        Choice {
            text: "Reload the list"
            onClicked: list.running = true
        }
    }
}
