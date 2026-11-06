// Idle & lock: when the screen locks and turns off by itself
// (idle.lockAfter / idle.screenOffAfter, used by lock/Idle.qml).
import QtQuick
import QtQuick.Layouts
import qs

Page {
    id: page
    title: "Idle & lock"
    description: "After how long without keyboard or mouse input the screen locks and the monitors turn off. A playing video holds both off. The screen always locks before the computer sleeps."

    readonly property var choices: [
        { label: "1 min", seconds: 60 }, { label: "2 min", seconds: 120 }, { label: "5 min", seconds: 300 },
        { label: "10 min", seconds: 600 }, { label: "15 min", seconds: 900 }, { label: "30 min", seconds: 1800 },
        { label: "1 hour", seconds: 3600 }, { label: "Never", seconds: 0 }
    ]

    Label {
        heading: true
        text: Theme.icons.lock + "  Lock the screen after"
    }
    Flow {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: page.choices
            Choice {
                required property var modelData
                text: modelData.label
                selected: Settings.lockAfter === modelData.seconds
                onClicked: Settings.set(".idle.lockAfter", modelData.seconds)
            }
        }
    }

    Label {
        heading: true
        text: Theme.icons.display + "  Turn the screen off after"
    }
    Flow {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: page.choices
            Choice {
                required property var modelData
                text: modelData.label
                selected: Settings.screenOffAfter === modelData.seconds
                onClicked: Settings.set(".idle.screenOffAfter", modelData.seconds)
            }
        }
    }

    Label {
        dim: true
        visible: Settings.lockAfter !== 0 && Settings.screenOffAfter !== 0 && Settings.screenOffAfter < Settings.lockAfter
        text: "The screen turns off before it locks: moving the mouse wakes it without a password until the lock time."
    }

    Choice {
        text: Theme.icons.lock + "  Lock now"
        onClicked: {
            SettingsState.open = false;
            LockState.lock();
        }
    }
}
