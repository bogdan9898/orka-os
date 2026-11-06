// Theme: pick one of the installed themes (/usr/share/orka/themes and your
// own in ~/.config/orka/themes). Applies at once to the shell, Hyprland,
// Ghostty, Neovim and the GTK light/dark preference.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs

Page {
    id: page
    title: "Theme"
    description: "Colors for the desktop, the terminal and Neovim. Put your own themes in ~/.config/orka/themes/<name>/theme.json (see /usr/share/orka/themes/README.md)."

    readonly property string userDir: Quickshell.env("HOME") + "/.config/orka/themes"
    property var themes: []

    onVisibleChanged: {
        if (visible)
            list.running = true;
    }

    Process {
        id: list
        running: true
        command: ["orka-settings", "themes"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    page.themes = JSON.parse(text);
                } catch (e) {
                    page.themes = [];
                }
            }
        }
    }

    Flow {
        Layout.fillWidth: true
        spacing: 14

        Repeater {
            model: page.themes

            Rectangle {
                id: card
                required property var modelData
                readonly property var c: modelData.colors || {}
                readonly property bool current: modelData.id === Settings.theme
                width: 210
                height: 130
                color: c.background || "#000000"
                border.width: current ? 3 : 1
                border.color: current ? Theme.accent : Qt.alpha(Theme.foreground, 0.3)

                Column {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    Row {
                        spacing: 6
                        Repeater {
                            model: ["accent", "accent2", "urgent", "inactive", "foreground"]
                            Rectangle {
                                required property string modelData
                                width: 22
                                height: 22
                                radius: 11
                                color: card.c[modelData] || "transparent"
                                border.width: 1
                                border.color: Qt.alpha(card.c.foreground || "#ffffff", 0.3)
                            }
                        }
                    }
                    Text {
                        width: parent.width
                        text: card.modelData.name || card.modelData.id
                        color: card.c.foreground || "#ffffff"
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize + 2
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: (card.modelData.mode === "light" ? "light" : "dark") + (card.modelData.user ? " · yours" : "") + (card.current ? " · " + Theme.icons.check + " in use" : "")
                        color: card.c.foreground || "#ffffff"
                        opacity: 0.7
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Settings.set(".theme", card.modelData.id)
                }
            }
        }
    }

    RowLayout {
        spacing: 8
        Choice {
            text: Theme.icons.folder + "  Open my themes folder"
            onClicked: Quickshell.execDetached(["xdg-open", page.userDir])
        }
        Choice {
            text: "Reload the list"
            onClicked: list.running = true
        }
    }
}
