// Red dot while a screen recording runs (ALT + PRINT); click to stop it.
import QtQuick
import Quickshell
import Quickshell.Io
import qs

BarIcon {
    id: root
    property bool recording: false

    visible: recording
    color: Theme.urgent
    text: Theme.icons.recording
    onClicked: Apps.run(["orka-screenrecord"])

    Process {
        id: check
        command: ["pgrep", "-f", "^gpu-screen-recorder"]
        onExited: code => root.recording = code === 0
    }
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: check.running = true
    }
}
