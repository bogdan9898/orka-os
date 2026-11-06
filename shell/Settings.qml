pragma Singleton
// OrkaOS settings the shell uses, from ~/.config/orka/settings.json. The file
// is watched, so edits apply right away. Meant to be written by a settings
// app later; until then edit it by hand. Missing values use the defaults below.
//
//   { "idle": { "lockAfter": 300, "screenOffAfter": 330 } }
//     seconds of inactivity until the screen locks / turns off; 0 = never
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

    function number(value, fallback) {
        return typeof value === "number" && value >= 0 ? Math.round(value) : fallback;
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
