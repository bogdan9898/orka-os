pragma Singleton
// Colors, font and icons for the whole shell. The colors come from the
// current OrkaOS theme (Settings → Theme; ~/.config/orka/current/theme.json,
// written by orka-settings) and change as soon as the theme does. Without a
// theme file: the Orka defaults below.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var theme: ({})
    readonly property var colors: theme.colors || {}

    readonly property color background: colors.background || "#0d1620"
    readonly property color foreground: colors.foreground || "#dce6ef"
    readonly property color accent: colors.accent || "#3fa7d6"
    readonly property color urgent: colors.urgent || "#ef6461"
    readonly property color inactive: colors.inactive || "#2e3d4d"
    readonly property bool light: theme.mode === "light"

    // The OrkaOS logo (branding/logo, installed by orka-install): the badge
    // without the name (bar, small places) and the full one with "Orka OS".
    // Both have the black disc, so they look the same in every theme.
    readonly property string logoBadge: "file:///usr/share/orka/branding/orkaos-badge.svg"
    readonly property string logoFull: "file:///usr/share/orka/branding/orkaos-logo-badge.svg"

    FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/orka/current/theme.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.theme = JSON.parse(text()) || {};
            } catch (e) {
                root.theme = {};
            }
        }
        onLoadFailed: root.theme = {}
    }

    // The interface font (Settings → Fonts), else JetBrainsMono Nerd Font.
    // Its size is in points for apps; the shell scales from its 12 px at the
    // GTK default of 11 pt. The icons below are Nerd Font glyphs: with
    // another font they come from JetBrainsMono Nerd Font through font
    // fallback.
    readonly property string defaultFont: "JetBrainsMono Nerd Font"
    readonly property string font: Settings.interfaceFont || defaultFont
    readonly property int fontSize: Settings.interfaceFontSize > 0 ? Math.round(Settings.interfaceFontSize * 12 / 11) : 12
    readonly property int barHeight: 26

    // Nerd Font glyphs (Material Design range), same as Omarchy's bar.
    readonly property var icons: ({
        workspace:   String.fromCodePoint(0xF14FB),   // the active workspace
        cpu:         String.fromCodePoint(0xF035B),
        recording:   String.fromCodePoint(0xF0EC2),
        dnd:         String.fromCodePoint(0xF009B),   // bell with a slash
        bell:        String.fromCodePoint(0xF009C),   // bell outline
        bellBadge:   String.fromCodePoint(0xF116B),   // bell with a dot: missed notifications
        close:       String.fromCodePoint(0xF0156),
        cup:         String.fromCodePoint(0xF06CA),   // coffee outline: keep awake off
        cupFull:     String.fromCodePoint(0xF0176),   // coffee: keep awake on
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
        settings:    String.fromCodePoint(0xF0493),   // cog
        palette:     String.fromCodePoint(0xF03D8),
        image:       String.fromCodePoint(0xF02E9),
        cursor:      String.fromCodePoint(0xF01BF),   // cursor-default-outline
        animation:   String.fromCodePoint(0xF05D8),   // animation (stacked frames)
        display:     String.fromCodePoint(0xF0379),   // monitor
        keyboard:    String.fromCodePoint(0xF030C),
        timer:       String.fromCodePoint(0xF051B),
        check:       String.fromCodePoint(0xF012C),
        folder:      String.fromCodePoint(0xF024B),
        font:        String.fromCodePoint(0xF0284),   // format-font
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
