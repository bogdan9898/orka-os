// Keyboard: layouts (and the key that switches between them) and key repeat.
// Written to Hyprland's input settings through orka-settings.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs

Page {
    id: page
    title: "Keyboard"
    description: "Keyboard layouts and how fast a held key repeats. The first layout is the one you start with."

    property var allLayouts: []     // [{ code, name }] from xkeyboard-config
    property string search: ""
    readonly property var matches: {
        const q = search.trim().toLowerCase();
        if (q === "")
            return [];
        return allLayouts.filter(l => !Settings.layouts.includes(l.code)
            && (l.code.startsWith(q) || l.name.toLowerCase().includes(q))).slice(0, 8);
    }
    readonly property var switchKeys: [
        { label: "None", option: "" },
        { label: "Alt + Shift", option: "grp:alt_shift_toggle" },
        { label: "Ctrl + Shift", option: "grp:ctrl_shift_toggle" },
        { label: "Both Alt keys", option: "grp:alts_toggle" },
        { label: "Caps Lock", option: "grp:caps_toggle" }
    ]

    function nameOf(code) {
        const l = allLayouts.find(x => x.code === code);
        return l ? l.name : code;
    }
    function setLayouts(list) {
        Settings.set(".keyboard.layouts", list);
    }

    Process {
        running: true
        command: ["awk", "/^! layout/ { on = 1; next } /^!/ { on = 0 } on { code = $1; $1 = \"\"; sub(/^ +/, \"\"); print code \"\\t\" $0 }", "/usr/share/X11/xkb/rules/base.lst"]
        stdout: StdioCollector {
            onStreamFinished: page.allLayouts = text.split("\n").filter(l => l !== "").map(l => {
                const [code, name] = l.split("\t");
                return { code: code, name: name };
            })
        }
    }

    Label {
        heading: true
        text: Theme.icons.keyboard + "  Layouts"
    }
    Flow {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: Settings.layouts
            Choice {
                required property string modelData
                required property int index
                text: page.nameOf(modelData) + " (" + modelData + ")" + (Settings.layouts.length > 1 ? "   ×" : "")
                selected: index === 0
                onClicked: {
                    if (Settings.layouts.length > 1)
                        page.setLayouts(Settings.layouts.filter(l => l !== modelData));
                }
            }
        }
    }
    Label {
        dim: true
        visible: Settings.layouts.length > 1
        text: "Click a layout to remove it."
    }

    // Add a layout: type to search.
    Rectangle {
        Layout.preferredWidth: 360
        implicitHeight: 32
        color: "transparent"
        border.width: 1
        border.color: addInput.activeFocus ? Theme.accent : Qt.alpha(Theme.foreground, 0.3)
        TextInput {
            id: addInput
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.foreground
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            clip: true
            onTextChanged: page.search = text
            onAccepted: {
                if (page.matches.length) {
                    page.setLayouts(Settings.layouts.concat([page.matches[0].code]));
                    text = "";
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: addInput.text === ""
                text: "Add a layout: type e.g. \"romanian\" or \"de\""
                color: Theme.foreground
                opacity: 0.4
                font: addInput.font
            }
        }
    }
    Flow {
        Layout.fillWidth: true
        visible: page.matches.length > 0
        spacing: 6
        Repeater {
            model: page.matches
            Choice {
                required property var modelData
                text: "+ " + modelData.name + " (" + modelData.code + ")"
                onClicked: {
                    page.setLayouts(Settings.layouts.concat([modelData.code]));
                    addInput.text = "";
                }
            }
        }
    }

    Label {
        visible: Settings.layouts.length > 1
        text: "Switch layouts with"
    }
    Flow {
        Layout.fillWidth: true
        visible: Settings.layouts.length > 1
        spacing: 6
        Repeater {
            model: page.switchKeys
            Choice {
                required property var modelData
                text: modelData.label
                selected: Settings.layoutSwitch === modelData.option
                onClicked: Settings.set(".keyboard.switch", modelData.option)
            }
        }
    }

    Label {
        heading: true
        text: "Key repeat"
    }
    GridLayout {
        columns: 3
        columnSpacing: 12
        rowSpacing: 10

        Label {
            Layout.fillWidth: false
            text: "Delay before repeating"
        }
        Slider {
            id: delay
            Layout.preferredWidth: 300
            from: 150
            to: 800
            stepSize: 25
            value: Settings.repeatDelay
            onReleased: v => Settings.set(".keyboard.repeatDelay", v)
        }
        Label {
            Layout.fillWidth: false
            text: delay.value + " ms"
        }

        Label {
            Layout.fillWidth: false
            text: "Repeat speed"
        }
        Slider {
            id: rate
            Layout.preferredWidth: 300
            from: 10
            to: 60
            stepSize: 1
            value: Settings.repeatRate
            onReleased: v => Settings.set(".keyboard.repeatRate", v)
        }
        Label {
            Layout.fillWidth: false
            text: rate.value + " per second"
        }
    }

    Rectangle {
        Layout.preferredWidth: 360
        implicitHeight: 32
        color: "transparent"
        border.width: 1
        border.color: tryInput.activeFocus ? Theme.accent : Qt.alpha(Theme.foreground, 0.3)
        TextInput {
            id: tryInput
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.foreground
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            clip: true
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: tryInput.text === ""
                text: "Try it here: hold a key"
                color: Theme.foreground
                opacity: 0.4
                font: tryInput.font
            }
        }
    }
}
