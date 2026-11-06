// On-screen display (like SwayOSD): a small card at the bottom of the focused
// monitor for volume, microphone mute, media keys and messages from scripts.
// Never takes input; hides after a moment. Adapted from Omarchy's Quickshell
// OSD (plugins/osd, MIT).
//
//   Volume / mute:   shown on any change of the default output (keys, the
//                    bar, a mixer), not at startup or when the output changes.
//   Microphone:      shown when the default input is muted or unmuted.
//   Media keys:      `orka-osd media` after playerctl: play state and track.
//   Scripts:         `orka-osd <icon> <message> [value 0-100]`
//                    (IPC target "osd": display, media, hide; not "show", which `qs ipc` takes as its own command).
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import qs

Scope {
    id: root
    property bool opened: false
    property string icon: ""
    property string message: ""
    property int value: -1        // 0-100 shows a bar, -1 a message only
    readonly property bool hasBar: value >= 0

    function show(icon, message, value) {
        root.icon = icon;
        root.message = message;
        root.value = value === undefined ? -1 : Math.max(-1, Math.min(100, value));
        opened = true;
        hideTimer.restart();
    }

    // Icon names scripts can use (anything else is shown as given).
    function iconFor(name) {
        const icons = {
            volume: Theme.icons.volume[2], muted: Theme.icons.muted,
            mic: Theme.icons.mic, "mic-off": Theme.icons.micOff,
            play: Theme.icons.play, pause: Theme.icons.pause, media: Theme.icons.music,
            night: Theme.icons.night, lock: Theme.icons.lock, info: Theme.icons.info
        };
        return icons[name] ?? name;
    }

    Timer {
        id: hideTimer
        interval: 1200
        onTriggered: root.opened = false
    }

    // --- Volume and microphone ---------------------------------------------
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    // Values arrive (and change) while things start up or the device changes:
    // don't show those.
    property bool armed: false
    Timer {
        id: armTimer
        interval: 1500
        running: true
        onTriggered: root.armed = true
    }
    onSinkChanged: {
        armed = false;
        armTimer.restart();
    }
    onSourceChanged: {
        armed = false;
        armTimer.restart();
    }

    function showVolume() {
        if (!armed || !sink || !sink.audio)
            return;
        const percent = Math.round(sink.audio.volume * 100);
        const icon = sink.audio.muted || percent === 0 ? Theme.icons.muted
            : Theme.icons.volume[percent < 34 ? 0 : percent < 67 ? 1 : 2];
        show(icon, sink.audio.muted ? "Muted" : percent + "%", sink.audio.muted ? 0 : percent);
    }

    Connections {
        target: root.sink ? root.sink.audio : null
        function onVolumeChanged() {
            root.showVolume();
        }
        function onMutedChanged() {
            root.showVolume();
        }
    }
    Connections {
        target: root.source ? root.source.audio : null
        function onMutedChanged() {
            if (root.armed)
                root.show(root.source.audio.muted ? Theme.icons.micOff : Theme.icons.mic,
                          root.source.audio.muted ? "Microphone off" : "Microphone on");
        }
    }

    // --- Media keys -----------------------------------------------------------
    // Called right after playerctl; the player needs a moment to update.
    Timer {
        id: mediaTimer
        interval: 350
        onTriggered: {
            const players = Mpris.players.values;
            const p = players.find(x => x.isPlaying) ?? players[0];
            if (!p) {
                root.show(Theme.icons.music, "No media player");
                return;
            }
            const track = [p.trackTitle, p.trackArtist].filter(s => s).join(" — ") || p.identity;
            root.show(p.isPlaying ? Theme.icons.play : Theme.icons.pause, track);
        }
    }

    IpcHandler {
        target: "osd"

        // value: "0".."100" for a bar, anything else (e.g. "none") for none.
        function display(icon: string, message: string, value: string): void {
            const v = parseInt(value, 10);
            root.show(root.iconFor(icon), message, isNaN(v) ? -1 : v);
        }
        function media(): void {
            mediaTimer.restart();
        }
        function hide(): void {
            root.opened = false;
        }
    }

    // --- The card -----------------------------------------------------------
    PanelWindow {
        screen: Quickshell.screens.find(s => Hyprland.focusedMonitor && s.name === Hyprland.focusedMonitor.name) ?? Quickshell.screens[0]
        visible: root.opened || card.opacity > 0

        anchors.bottom: true
        margins.bottom: 80
        implicitWidth: card.width
        implicitHeight: card.height
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "orka-osd"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region {}   // never takes clicks: they go to whatever is below
        color: "transparent"

        Rectangle {
            id: card
            readonly property int pad: 16
            width: row.implicitWidth + 2 * pad
            height: 60
            color: Qt.alpha(Theme.background, 0.97)
            border.width: 2
            border.color: Theme.accent
            opacity: root.opened ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }

            Row {
                id: row
                anchors.centerIn: parent
                spacing: 16

                Text {
                    // Fixed width, so the bar doesn't move when the volume icon changes.
                    width: 32
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: root.icon
                    color: Theme.foreground
                    font.family: Theme.font
                    font.pixelSize: 26
                }

                Rectangle {
                    visible: root.hasBar
                    width: 160
                    height: 6
                    anchors.verticalCenter: parent.verticalCenter
                    color: Qt.alpha(Theme.foreground, 0.3)

                    Rectangle {
                        height: parent.height
                        width: parent.width * Math.max(0, root.value) / 100
                        color: Theme.accent

                        Behavior on width {
                            enabled: root.opened
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                Text {
                    // A bar's readout is as wide as "100%", so it doesn't jitter.
                    width: root.hasBar ? Math.max(implicitWidth, hundred.width) : Math.min(implicitWidth, 420)
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: root.hasBar ? Text.AlignRight : Text.AlignLeft
                    visible: text !== ""
                    text: root.message
                    color: Theme.foreground
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 4
                    font.bold: true
                    elide: Text.ElideRight
                }
            }

            TextMetrics {
                id: hundred
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 4
                font.bold: true
                text: "100%"
            }
        }
    }
}
