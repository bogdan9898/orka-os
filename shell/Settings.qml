pragma Singleton
// OrkaOS settings, from ~/.config/orka/settings.json (watched: changes apply
// right away). Written by the settings app (settings/SettingsApp.qml) through
// `orka-settings set`, which also applies them (theme, wallpaper, monitors,
// keyboard, night light); the shell itself uses the idle times. Missing
// values use the defaults below.
//
//   theme            "orka"           a theme directory name (orka-settings themes)
//   wallpaper        ""               an image path; "" = the theme's wallpaper or color
//   idle             { lockAfter: 300, screenOffAfter: 330 }   seconds, 0 = never
//   nightlight       { on: false, temperature: 4000 }
//   keyboard         { layouts: ["us"], switch: "", repeatRate: 40, repeatDelay: 250 }
//   cursor           { theme: "Bibata-Modern-Classic", size: 24 }   (orka-settings cursors)
//   monitors         { "DP-1": { mode: "2560x1440@165", scale: 1 } }
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property string path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/orka/settings.json"

    property var data: ({})
    readonly property var idle: data.idle || {}
    readonly property int lockAfter: number(idle.lockAfter, 300)
    readonly property int screenOffAfter: number(idle.screenOffAfter, 330)

    readonly property string theme: data.theme || "orka"
    readonly property string wallpaper: data.wallpaper || ""
    readonly property var nightlight: data.nightlight || {}
    readonly property bool nightlightOn: nightlight.on === true
    readonly property int nightlightTemperature: number(nightlight.temperature, 4000)
    readonly property var keyboard: data.keyboard || {}
    readonly property var layouts: keyboard.layouts && keyboard.layouts.length ? keyboard.layouts : ["us"]
    readonly property string layoutSwitch: keyboard.switch || ""
    readonly property int repeatRate: number(keyboard.repeatRate, 40)
    readonly property int repeatDelay: number(keyboard.repeatDelay, 250)
    readonly property var cursor: data.cursor || {}
    readonly property string cursorTheme: cursor.theme || "Bibata-Modern-Classic"
    readonly property int cursorSize: number(cursor.size, 24)
    readonly property var monitors: data.monitors || {}

    function number(value, fallback) {
        return typeof value === "number" && value >= 0 ? Math.round(value) : fallback;
    }

    // Change one value (a jq path such as ".idle.lockAfter") and apply it.
    function set(path, value) {
        Quickshell.execDetached(["orka-settings", "set", path, JSON.stringify(value)]);
    }

    FileView {
        path: root.path
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.data = JSON.parse(text()) || {};
            } catch (e) {
                console.warn("orka: " + root.path + " is not valid JSON, using defaults: " + e);
                root.data = {};
            }
        }
        onLoadFailed: root.data = {}
    }
}
