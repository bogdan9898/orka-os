// OrkaOS Settings (SUPER + ALT + SPACE): a window over the focused monitor
// with a page list on the left. Every change is stored in
// ~/.config/orka/settings.json and applied right away through orka-settings.
// Escape or a click outside closes it.
//
// The pages are created once and only hidden, so a pending display change
// still goes back by itself after its 15 s when the window is closed.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs

Scope {
    id: root

    readonly property var pages: [
        { id: "theme", label: "Theme", icon: Theme.icons.palette },
        { id: "wallpaper", label: "Wallpaper", icon: Theme.icons.image },
        { id: "cursor", label: "Mouse cursor", icon: Theme.icons.cursor },
        { id: "animations", label: "Animations", icon: Theme.icons.animation },
        { id: "display", label: "Display", icon: Theme.icons.display },
        { id: "idle", label: "Idle & lock", icon: Theme.icons.lock },
        { id: "sound", label: "Sound", icon: Theme.icons.volume[2] },
        { id: "nightlight", label: "Night light", icon: Theme.icons.night },
        { id: "keyboard", label: "Keyboard", icon: Theme.icons.keyboard },
        { id: "about", label: "About", icon: Theme.icons.info }
    ]

    PanelWindow {
        screen: Quickshell.screens.find(s => Hyprland.focusedMonitor && s.name === Hyprland.focusedMonitor.name) ?? Quickshell.screens[0]
        visible: SettingsState.open

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "orka-settings"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        color: "#99000000"

        onVisibleChanged: {
            if (visible)
                Qt.callLater(() => card.forceActiveFocus());
        }

        MouseArea {
            anchors.fill: parent
            onClicked: SettingsState.open = false
        }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: Math.min(1100, parent.width - 80)
            height: Math.min(760, parent.height - 80)
            color: Theme.background
            border.width: 2
            border.color: Theme.accent
            focus: true
            Keys.onEscapePressed: SettingsState.open = false

            MouseArea {
                anchors.fill: parent   // clicks inside don't close it
                onClicked: card.forceActiveFocus()
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 2
                spacing: 0

                // Page list.
                Rectangle {
                    Layout.preferredWidth: 220
                    Layout.fillHeight: true
                    color: Qt.alpha(Theme.foreground, 0.05)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 4

                        Text {
                            Layout.bottomMargin: 12
                            text: Theme.icons.settings + "  Settings"
                            color: Theme.foreground
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize + 6
                            font.bold: true
                        }

                        Repeater {
                            model: root.pages
                            Rectangle {
                                id: entry
                                required property var modelData
                                readonly property bool current: SettingsState.page === modelData.id
                                Layout.fillWidth: true
                                implicitHeight: 36
                                color: current ? Theme.accent : entryArea.containsMouse ? Qt.alpha(Theme.accent, 0.2) : "transparent"

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    text: entry.modelData.icon + "   " + entry.modelData.label
                                    color: entry.current ? Theme.background : Theme.foreground
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize + 1
                                    font.bold: entry.current
                                }
                                MouseArea {
                                    id: entryArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: SettingsState.page = entry.modelData.id
                                }
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Esc to close"
                            color: Theme.foreground
                            opacity: 0.5
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                        }
                    }
                }

                // The pages (one visible).
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 28

                    ThemePage { anchors.fill: parent; visible: SettingsState.page === "theme" }
                    WallpaperPage { anchors.fill: parent; visible: SettingsState.page === "wallpaper" }
                    CursorPage { anchors.fill: parent; visible: SettingsState.page === "cursor" }
                    AnimationsPage { anchors.fill: parent; visible: SettingsState.page === "animations" }
                    DisplayPage { anchors.fill: parent; visible: SettingsState.page === "display" }
                    IdlePage { anchors.fill: parent; visible: SettingsState.page === "idle" }
                    SoundPage { anchors.fill: parent; visible: SettingsState.page === "sound" }
                    NightLightPage { anchors.fill: parent; visible: SettingsState.page === "nightlight" }
                    KeyboardPage { anchors.fill: parent; visible: SettingsState.page === "keyboard" }
                    AboutPage { anchors.fill: parent; visible: SettingsState.page === "about" }
                }
            }
        }
    }
}
