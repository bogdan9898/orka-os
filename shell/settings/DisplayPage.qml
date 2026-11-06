// Display: resolution, refresh rate and scale per monitor, from the modes the
// monitor reports (hyprctl monitors). After a change: "Keep?" for 15 seconds,
// then the old mode comes back by itself, in case the screen went blank.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs

Page {
    id: page
    title: "Display"
    description: "Resolution, refresh rate and scale. A change is undone after 15 seconds unless you keep it."

    property var monitors: []
    property var pending: ({})      // monitor name -> { mode, scale } chosen, not applied yet
    property var revert: null       // { name, mode, scale } to go back to, while asking
    property int countdown: 0

    onVisibleChanged: {
        if (visible)
            refresh();
    }

    function refresh() {
        query.running = true;
    }

    // "2560x1440@165.00Hz" -> "2560x1440@165"
    function cleanMode(m) {
        const r = m.match(/^(\d+)x(\d+)@([\d.]+)/);
        return r ? r[1] + "x" + r[2] + "@" + parseFloat(r[3]).toString() : m;
    }
    function modesOf(mon) {
        const seen = {};
        const out = [];
        for (const m of mon.availableModes || []) {
            const c = cleanMode(m);
            if (!seen[c]) {
                seen[c] = true;
                out.push(c);
            }
        }
        const key = s => s.split(/[x@]/).map(Number);
        return out.sort((a, b) => {
            const [aw, ah, ar] = key(a), [bw, bh, br] = key(b);
            return bw * bh - aw * ah || br - ar;
        });
    }
    function currentMode(mon) {
        return mon.width + "x" + mon.height + "@" + parseFloat(mon.refreshRate.toFixed(2)).toString();
    }
    function choice(mon) {
        return pending[mon.name] || { mode: currentMode(mon), scale: mon.scale };
    }
    function choose(mon, key, value) {
        const p = Object.assign({}, pending);
        p[mon.name] = Object.assign({}, choice(mon));
        p[mon.name][key] = value;
        pending = p;
    }
    function apply(mon) {
        const c = choice(mon);
        revert = { name: mon.name, mode: currentMode(mon), scale: mon.scale };
        Settings.set(".monitors[" + JSON.stringify(mon.name) + "]", { mode: c.mode, scale: c.scale });
        const p = Object.assign({}, pending);
        delete p[mon.name];
        pending = p;
        countdown = 15;
        tick.start();
        refreshLater.restart();
    }
    function keep() {
        tick.stop();
        revert = null;
    }
    function undo() {
        tick.stop();
        if (revert)
            Settings.set(".monitors[" + JSON.stringify(revert.name) + "]", { mode: revert.mode, scale: revert.scale });
        revert = null;
        refreshLater.restart();
    }

    Process {
        id: query
        running: true
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    page.monitors = JSON.parse(text);
                } catch (e) {
                    page.monitors = [];
                }
            }
        }
    }
    Timer {
        id: refreshLater
        interval: 1500
        onTriggered: page.refresh()
    }
    Timer {
        id: tick
        interval: 1000
        repeat: true
        onTriggered: {
            page.countdown--;
            if (page.countdown <= 0)
                page.undo();
        }
    }

    // While a change waits for confirmation.
    Rectangle {
        Layout.fillWidth: true
        visible: page.revert !== null
        implicitHeight: confirm.implicitHeight + 24
        color: Qt.alpha(Theme.accent, 0.15)
        border.width: 2
        border.color: Theme.accent

        RowLayout {
            id: confirm
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12
            Label {
                text: "Keep this display setting? Going back in " + page.countdown + " s."
                font.bold: true
            }
            Choice {
                text: "Keep"
                selected: true
                onClicked: page.keep()
            }
            Choice {
                text: "Go back"
                onClicked: page.undo()
            }
        }
    }

    Label {
        visible: page.monitors.length === 0
        text: "No monitors found (is Hyprland running?)."
        dim: true
    }

    Repeater {
        model: page.monitors

        ColumnLayout {
            id: monitor
            required property var modelData
            readonly property var chosen: page.choice(modelData)
            readonly property bool changed: page.pending[modelData.name] !== undefined
            Layout.fillWidth: true
            spacing: 10

            Label {
                heading: true
                text: Theme.icons.display + "  " + monitor.modelData.name + "  ·  " + (monitor.modelData.description || "")
            }
            Label {
                dim: true
                text: "Now: " + page.currentMode(monitor.modelData) + " Hz, scale " + monitor.modelData.scale
            }

            Label {
                text: "Resolution and refresh rate"
            }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: page.modesOf(monitor.modelData)
                    Choice {
                        required property string modelData
                        text: modelData.replace("@", " @ ") + " Hz"
                        selected: monitor.chosen.mode === modelData
                        onClicked: page.choose(monitor.modelData, "mode", modelData)
                    }
                }
            }

            Label {
                text: "Scale"
            }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: [1, 1.25, 1.5, 1.75, 2]
                    Choice {
                        required property real modelData
                        text: Math.round(modelData * 100) + "%"
                        selected: Math.abs(monitor.chosen.scale - modelData) < 0.01
                        onClicked: page.choose(monitor.modelData, "scale", modelData)
                    }
                }
            }

            Choice {
                text: "Apply"
                selected: monitor.changed
                opacity: monitor.changed ? 1 : 0.5
                onClicked: {
                    if (monitor.changed)
                        page.apply(monitor.modelData);
                }
            }
        }
    }
}
