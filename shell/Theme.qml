pragma Singleton
// Colors, font and icons for the whole shell. Placeholder colors until the
// Orka theme is designed (roadmap TODO); they match orka/theme.lua.
import QtQuick
import Quickshell

Singleton {
    readonly property color background: "#1a1a1a"
    readonly property color foreground: "#e0e0e0"
    readonly property color accent: "#1793d1"
    readonly property color urgent: "#e05252"

    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 12
    readonly property int barHeight: 26

    // Nerd Font glyphs (Material Design range), same as Omarchy's bar.
    readonly property var icons: ({
        logo:        String.fromCodePoint(0xF023A),   // fish, until the Orka logo exists
        workspace:   String.fromCodePoint(0xF14FB),   // the active workspace
        cpu:         String.fromCodePoint(0xF035B),
        recording:   String.fromCodePoint(0xF0EC2),
        dnd:         String.fromCodePoint(0xF009B),   // bell with a slash
        lock:        String.fromCodePoint(0xF033E),
        mic:         String.fromCodePoint(0xF036C),
        micOff:      String.fromCodePoint(0xF036D),
        play:        String.fromCodePoint(0xF040A),
        pause:       String.fromCodePoint(0xF03E4),
        music:       String.fromCodePoint(0xF075A),
        night:       String.fromCodePoint(0xF0594),   // moon
        info:        String.fromCodePoint(0xF02FD),
        capsLock:    String.fromCodePoint(0xF0632),   // keyboard-caps
        numLock:     String.fromCodePoint(0xF03A0),   // numeric
        btOn:        String.fromCodePoint(0xF293),
        btOff:       String.fromCodePoint(0xF00B2),
        btConnected: String.fromCodePoint(0xF00B1),
        ethernet:    String.fromCodePoint(0xF0002),
        offline:     String.fromCodePoint(0xF092E),
        wifi:        [0xF092F, 0xF091F, 0xF0922, 0xF0925, 0xF0928].map(c => String.fromCodePoint(c)),
        volume:      [0xF057F, 0xF0580, 0xF057E].map(c => String.fromCodePoint(c)),
        muted:       String.fromCodePoint(0xF075F)
    })
}
