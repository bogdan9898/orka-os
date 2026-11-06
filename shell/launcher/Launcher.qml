// App launcher (SUPER + SPACE). Type to search the installed apps; Enter
// starts the selected one, or runs what you typed as a command when no app
// matches. Apps you start often are listed first; the counts are kept in
// ~/.local/state/orka/launcher.json.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs

Scope {
    id: root

    readonly property string statePath: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/orka/launcher.json"
    property var usage: ({})   // desktop entry id -> times started

    property string query: ""
    readonly property var results: search(query, DesktopEntries.applications.values, usage)

    // Higher is better; -1 = no match.
    function score(entry, q) {
        const name = entry.name.toLowerCase();
        if (name.startsWith(q))
            return 100;
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q)))
            return 80;
        if (name.includes(q))
            return 60;
        let i = 0;   // the letters of q, in order ("ffx" -> Firefox)
        for (const c of name)
            if (c === q[i] && ++i === q.length)
                return 40;
        const other = [entry.genericName, entry.keywords, entry.comment, entry.id].join(" ").toLowerCase();
        return other.includes(q) ? 20 : -1;
    }

    function search(text, entries, counts) {
        const q = text.trim().toLowerCase();
        const list = [];
        for (const e of entries) {
            if (e.noDisplay)
                continue;
            const s = q === "" ? 0 : score(e, q);
            if (s >= 0)
                list.push({ entry: e, score: s + Math.min(counts[e.id] || 0, 20) });
        }
        list.sort((a, b) => b.score - a.score || a.entry.name.localeCompare(b.entry.name));
        return list.map(x => x.entry);
    }

    function launch(entry) {
        // Through uwsm, like the key bindings; Terminal=true apps open in Ghostty
        // (xdg-terminal-exec).
        Quickshell.execDetached(["uwsm", "app", "--", entry.id + ".desktop"]);
        const counts = Object.assign({}, usage);
        counts[entry.id] = (counts[entry.id] || 0) + 1;
        usage = counts;
        stateFile.setText(JSON.stringify(counts, null, 2) + "\n");
        LauncherState.open = false;
    }

    function runCommand(text) {
        Quickshell.execDetached(["uwsm", "app", "--", "sh", "-c", text]);
        LauncherState.open = false;
    }

    function accept() {
        if (list.count > 0)
            launch(results[list.currentIndex]);
        else if (query.trim() !== "")
            runCommand(query.trim());
    }

    // Mouse selection only after the pointer has really moved since opening:
    // when the list appears under a resting pointer, Wayland reports that as
    // pointer motion too, and Enter would start whatever is under it.
    property var pointerStart: null
    property bool pointerMoved: false
    function pointerAt(item, x, y) {
        const p = item.mapToItem(null, x, y);
        if (pointerStart === null)
            pointerStart = p;
        else if (Math.abs(p.x - pointerStart.x) + Math.abs(p.y - pointerStart.y) > 2)
            pointerMoved = true;
        return pointerMoved;
    }

    function move(step) {
        if (list.count > 0)
            list.currentIndex = (list.currentIndex + step + list.count) % list.count;
    }

    Process {
        running: true
        command: ["mkdir", "-p", root.statePath.substring(0, root.statePath.lastIndexOf("/"))]
    }
    FileView {
        id: stateFile
        path: root.statePath
        printErrors: false
        onLoaded: {
            try {
                root.usage = JSON.parse(text()) || {};
            } catch (e) {
                root.usage = {};
            }
        }
    }

    Connections {
        target: LauncherState
        function onOpenChanged() {
            if (LauncherState.open) {
                input.text = "";
                list.currentIndex = 0;
                root.pointerStart = null;
                root.pointerMoved = false;
                Qt.callLater(() => input.forceActiveFocus());
            }
        }
    }

    PanelWindow {
        screen: Quickshell.screens.find(s => Hyprland.focusedMonitor && s.name === Hyprland.focusedMonitor.name) ?? Quickshell.screens[0]
        visible: LauncherState.open

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "orka-launcher"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        color: "transparent"

        // A click outside the box closes it.
        MouseArea {
            anchors.fill: parent
            onClicked: LauncherState.open = false
        }

        Rectangle {
            id: box
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(parent.height * 0.2)
            width: 600
            implicitHeight: column.implicitHeight + 2 * border.width
            color: Theme.background
            border.width: 2
            border.color: Theme.accent

            MouseArea {
                anchors.fill: parent   // clicks inside don't close it
            }

            ColumnLayout {
                id: column
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: box.border.width
                spacing: 0

                // Search field.
                TextInput {
                    id: input
                    Layout.fillWidth: true
                    Layout.margins: 14
                    color: Theme.foreground
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 4
                    clip: true
                    focus: true
                    onTextChanged: {
                        root.query = text;
                        list.currentIndex = 0;
                    }
                    onAccepted: root.accept()
                    Keys.onEscapePressed: LauncherState.open = false
                    Keys.onUpPressed: root.move(-1)
                    Keys.onDownPressed: root.move(1)
                    Keys.onTabPressed: root.move(1)
                    Keys.onBacktabPressed: root.move(-1)
                    Keys.onPressed: event => {
                        if (!(event.modifiers & Qt.ControlModifier))
                            return;
                        if (event.key === Qt.Key_J || event.key === Qt.Key_N) {
                            root.move(1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_K || event.key === Qt.Key_P) {
                            root.move(-1);
                            event.accepted = true;
                        }
                    }

                    Text {
                        visible: input.text === ""
                        text: "Search apps, or type a command"
                        color: Theme.foreground
                        opacity: 0.4
                        font: input.font
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Theme.accent
                    opacity: 0.5
                }

                ListView {
                    id: list
                    Layout.fillWidth: true
                    implicitHeight: Math.min(count, 8) * 48
                    visible: count > 0
                    clip: true
                    model: root.results
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 0

                    delegate: Rectangle {
                        id: row
                        required property DesktopEntry modelData
                        required property int index
                        width: ListView.view.width
                        height: 48
                        color: ListView.isCurrentItem ? Qt.alpha(Theme.accent, 0.35) : "transparent"

                        MouseArea {
                            id: rowArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onPositionChanged: mouse => {
                                if (root.pointerAt(rowArea, mouse.x, mouse.y))
                                    list.currentIndex = row.index;
                            }
                            onClicked: root.launch(row.modelData)
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 12

                            IconImage {
                                implicitSize: 28
                                source: Quickshell.iconPath(row.modelData.icon, true) || Quickshell.iconPath("application-x-executable", true)
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    Layout.fillWidth: true
                                    text: row.modelData.name
                                    color: Theme.foreground
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize + 1
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    visible: text !== ""
                                    text: row.modelData.genericName || row.modelData.comment
                                    color: Theme.foreground
                                    opacity: 0.6
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize - 1
                                    elide: Text.ElideRight
                                }
                            }
                            Text {
                                visible: row.modelData.runInTerminal
                                text: "terminal"
                                color: Theme.foreground
                                opacity: 0.4
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 1
                            }
                        }
                    }
                }

                // No app matches: Enter runs the text as a command.
                Text {
                    Layout.fillWidth: true
                    Layout.margins: 14
                    visible: list.count === 0
                    text: root.query.trim() === "" ? "No apps found" : "Enter: run  " + root.query.trim()
                    color: Theme.foreground
                    opacity: 0.7
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    elide: Text.ElideRight
                }
            }
        }
    }
}
