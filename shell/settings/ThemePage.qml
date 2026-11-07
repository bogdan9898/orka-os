// Theme: dark mode on/off (also SUPER + CTRL + D), and the theme for each
// mode, picked independently from the installed themes
// (/usr/share/orka/themes and your own in ~/.config/orka/themes). The theme
// of the current mode applies at once to the shell, Hyprland, Ghostty,
// Neovim, GTK/Qt apps, btop, and to apps that ask the system for dark or
// light mode (browsers, through the desktop portal).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs

Page {
    id: page
    title: "Theme"
    description: "Colors for the desktop, the apps, the terminal and Neovim. Put your own themes in ~/.config/orka/themes/<name>/theme.json (see /usr/share/orka/themes/README.md)."

    readonly property string userDir: Quickshell.env("HOME") + "/.config/orka/themes"
    property var themes: []
    readonly property var darkThemes: themes.filter(t => t.mode !== "light")
    readonly property var lightThemes: themes.filter(t => t.mode === "light")

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

    // Dark mode switch.
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: modeRow.implicitHeight + 28
        color: Qt.alpha(Theme.foreground, 0.04)
        border.width: 1
        border.color: Qt.alpha(Theme.foreground, 0.15)

        RowLayout {
            id: modeRow
            anchors.fill: parent
            anchors.margins: 14
            spacing: 14

            Text {
                text: String.fromCodePoint(0xF050E)   // theme-light-dark
                color: Theme.accent
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 12
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: "Dark mode"
                    color: Theme.foreground
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 3
                    font.bold: true
                }
                Text {
                    Layout.fillWidth: true
                    text: "Switches the whole system between your dark and light theme. Browsers and other apps that follow the system switch too. Shortcut: SUPER + CTRL + D."
                    color: Theme.foreground
                    opacity: 0.6
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    wrapMode: Text.Wrap
                }
            }
            Toggle {
                checked: Settings.darkMode
                onToggled: on => Settings.set(".appearance.mode", on ? "dark" : "light")
            }
        }
    }

    ThemeChoice {
        heading: String.fromCodePoint(0xF0594) + "  Theme in dark mode"
        themes: page.darkThemes
        selected: Settings.darkTheme
        active: Settings.darkMode
        onPicked: id => Settings.set(".appearance.dark", id)
    }

    ThemeChoice {
        heading: String.fromCodePoint(0xF0599) + "  Theme in light mode"
        themes: page.lightThemes
        selected: Settings.lightTheme
        active: !Settings.darkMode
        onPicked: id => Settings.set(".appearance.light", id)
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

    // One mode's themes as color cards; the picked one has a frame.
    component ThemeChoice: ColumnLayout {
        id: choice
        property string heading
        property var themes: []
        property string selected
        property bool active
        signal picked(string id)

        Layout.fillWidth: true
        spacing: 10

        Label {
            heading: true
            text: choice.heading + (choice.active ? "   ·  in use now" : "")
        }
        Label {
            dim: true
            visible: choice.themes.length === 0
            text: "No themes for this mode installed."
        }
        Flow {
            Layout.fillWidth: true
            spacing: 14

            Repeater {
                model: choice.themes

                Rectangle {
                    id: card
                    required property var modelData
                    readonly property var c: modelData.colors || {}
                    readonly property bool current: modelData.id === choice.selected
                    width: 210
                    height: 110
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
                            text: (card.modelData.name || card.modelData.id) + (card.current ? "  " + Theme.icons.check : "")
                            color: card.c.foreground || "#ffffff"
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize + 2
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            visible: card.modelData.user === true
                            text: "yours"
                            color: card.c.foreground || "#ffffff"
                            opacity: 0.7
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: choice.picked(card.modelData.id)
                    }
                }
            }
        }
    }
}
