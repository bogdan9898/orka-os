// Default audio output. Click: mixer (wiremix), right click: mute,
// scroll: volume in steps of 5%.
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs

BarIcon {
    id: root
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink !== null && sink.audio !== null
    readonly property real volume: ready ? sink.audio.volume : 0
    readonly property bool muted: !ready || sink.audio.muted

    // Pipewire only reports a node's volume while something tracks it.
    PwObjectTracker {
        objects: [root.sink]
    }

    text: muted ? Theme.icons.muted : Theme.icons.volume[volume < 0.34 ? 0 : volume < 0.67 ? 1 : 2]
    tooltip: muted ? "Volume: muted" : "Volume " + Math.round(volume * 100) + "%"
    onClicked: Apps.tui("wiremix")
    onRightClicked: if (ready) sink.audio.muted = !sink.audio.muted
    onScrolled: steps => {
        if (ready)
            sink.audio.volume = Math.max(0, Math.min(1, Math.round((volume + steps * 0.05) * 20) / 20));
    }
}
