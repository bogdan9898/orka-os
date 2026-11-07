// Animations: on/off, speed, how windows open and close, the workspace
// switch, and whether windows glide when they move or resize
// (settings.json .animations → current/hyprland.lua → orka/looknfeel.lua).
import QtQuick
import QtQuick.Layouts
import qs

Page {
    id: page
    title: "Animations"
    description: "How windows and the desktop move. Changes apply at once; try them by opening a window (SUPER + RETURN) or switching workspaces (SUPER + 1…5)."

    readonly property var speeds: [
        { label: "Relaxed", value: 1.5 }, { label: "Normal", value: 1 },
        { label: "Quick", value: 0.7 }, { label: "Snappy", value: 0.45 }
    ]
    readonly property var windowStyles: [
        { label: "Pop in", value: "popin", hint: "grows a little while it fades in" },
        { label: "Slide", value: "slide", hint: "slides in from the nearest edge" },
        { label: "Grow", value: "gnomed", hint: "unfolds from a line" },
        { label: "Fade only", value: "fade", hint: "fades in, no movement" }
    ]
    readonly property var workspaceStyles: [
        { label: "Off", value: "off", hint: "instant" },
        { label: "Slide", value: "slide", hint: "sideways" },
        { label: "Slide up/down", value: "slidevert", hint: "vertically" },
        { label: "Fade", value: "fade", hint: "cross-fade" },
        { label: "Slide + fade", value: "slidefade", hint: "a short slide with a fade" }
    ]

    // On/off.
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: onRow.implicitHeight + 28
        color: Qt.alpha(Theme.foreground, 0.04)
        border.width: 1
        border.color: Qt.alpha(Theme.foreground, 0.15)

        RowLayout {
            id: onRow
            anchors.fill: parent
            anchors.margins: 14
            spacing: 14

            Text {
                text: Theme.icons.animation
                color: Theme.accent
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 12
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: "Animations"
                    color: Theme.foreground
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 3
                    font.bold: true
                }
                Text {
                    Layout.fillWidth: true
                    text: Settings.animationsOn ? "Windows, popups and workspaces move smoothly. Turn off to make everything change instantly." : "Off: windows, popups and workspaces appear and change instantly."
                    color: Theme.foreground
                    opacity: 0.6
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    wrapMode: Text.Wrap
                }
            }
            Toggle {
                checked: Settings.animationsOn
                onToggled: on => Settings.set(".animations.enabled", on)
            }
        }
    }

    // The rest only matters while animations are on.
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 18
        enabled: Settings.animationsOn
        opacity: enabled ? 1 : 0.4

        Section {
            heading: "Speed"
            options: page.speeds
            current: Settings.animationSpeed
            onPicked: value => Settings.set(".animations.speed", value)
        }
        Section {
            heading: "Opening and closing windows"
            options: page.windowStyles
            current: Settings.windowAnimation
            onPicked: value => Settings.set(".animations.windows", value)
        }
        Section {
            heading: "Switching workspaces"
            options: page.workspaceStyles
            current: Settings.workspaceAnimation
            onPicked: value => Settings.set(".animations.workspaces", value)
        }

        Label {
            heading: true
            text: "Moving and resizing windows"
        }
        RowLayout {
            spacing: 14
            Toggle {
                checked: Settings.moveAnimation
                onToggled: on => Settings.set(".animations.moves", on)
            }
            Label {
                Layout.fillWidth: false
                dim: true
                text: Settings.moveAnimation ? "Windows glide to their new place and size." : "Windows jump to their new place and size."
            }
        }
    }

    // A heading, a row of choices and the picked one's description.
    component Section: ColumnLayout {
        id: section
        property string heading
        property var options: []
        property var current
        signal picked(var value)

        Layout.fillWidth: true
        spacing: 8

        Label {
            heading: true
            text: section.heading
        }
        Flow {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: section.options
                Choice {
                    required property var modelData
                    text: modelData.label
                    selected: section.current === modelData.value
                    onClicked: section.picked(modelData.value)
                }
            }
        }
        Label {
            dim: true
            readonly property var chosen: section.options.find(o => o.value === section.current)
            visible: !!chosen && !!chosen.hint
            text: chosen && chosen.hint ? chosen.hint.charAt(0).toUpperCase() + chosen.hint.slice(1) + "." : ""
        }
    }
}
