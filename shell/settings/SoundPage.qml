// Sound: the default output and input device and their volume (Pipewire).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs

Page {
    id: page
    title: "Sound"
    description: "Where sound plays and which microphone apps use. For per-app volume open the mixer (SUPER + CTRL + A)."

    readonly property var devices: Pipewire.nodes.values.filter(n => n.audio && !n.isStream)
    readonly property var outputs: devices.filter(n => n.isSink)
    readonly property var inputs: devices.filter(n => !n.isSink)

    PwObjectTracker {
        objects: page.devices
    }

    function label(node) {
        return node.description || node.nickname || node.name;
    }

    component DeviceGroup: ColumnLayout {
        id: group
        property string heading: ""
        property var nodes: []
        property PwNode current: null
        property bool input: false
        Layout.fillWidth: true
        spacing: 8

        Label {
            heading: true
            text: group.heading
        }
        Label {
            visible: group.nodes.length === 0
            dim: true
            text: "None found."
        }
        Repeater {
            model: group.nodes
            Choice {
                required property PwNode modelData
                Layout.fillWidth: true
                text: page.label(modelData)
                selected: group.current === modelData
                onClicked: {
                    if (group.input)
                        Pipewire.preferredDefaultAudioSource = modelData;
                    else
                        Pipewire.preferredDefaultAudioSink = modelData;
                }
            }
        }
        RowLayout {
            visible: group.current !== null && group.current.audio !== null
            spacing: 12
            Choice {
                text: group.current && group.current.audio && group.current.audio.muted
                    ? (group.input ? Theme.icons.micOff : Theme.icons.muted) + "  Muted"
                    : (group.input ? Theme.icons.mic : Theme.icons.volume[2]) + "  On"
                selected: group.current && group.current.audio ? group.current.audio.muted : false
                onClicked: group.current.audio.muted = !group.current.audio.muted
            }
            Slider {
                Layout.preferredWidth: 320
                from: 0
                to: 100
                stepSize: 1
                value: group.current && group.current.audio ? Math.round(group.current.audio.volume * 100) : 0
                onMoved: v => {
                    if (group.current && group.current.audio)
                        group.current.audio.volume = v / 100;
                }
            }
            Label {
                Layout.fillWidth: false
                text: group.current && group.current.audio ? Math.round(group.current.audio.volume * 100) + "%" : ""
            }
        }
    }

    DeviceGroup {
        heading: Theme.icons.volume[2] + "  Output"
        nodes: page.outputs
        current: Pipewire.defaultAudioSink
    }
    DeviceGroup {
        heading: Theme.icons.mic + "  Input"
        nodes: page.inputs
        current: Pipewire.defaultAudioSource
        input: true
    }
}
