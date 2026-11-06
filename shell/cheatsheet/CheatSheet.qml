// Keyboard shortcut cheat sheet (SUPER + K): every Hyprland binding (windows,
// apps, notifications, ...) and every tmux binding, grouped by section, in
// columns. Read fresh from `orka-keys` each time it opens, so it always shows
// the bindings as they are now. Type to filter; Escape or a click outside
// closes it. IPC target "cheatsheet": toggle | open | close.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs

Scope {
    id: root
    property bool open: false
    property bool loading: false
    property string error: ""
    property var rows: []        // [{ section, keys, description }]
    property string query: ""

    // As many columns of at least minColumnWidth as fit, sharing the width.
    readonly property int minColumnWidth: 340
    readonly property int gap: 32
    property int columnCount: 1
    property int columnWidth: minColumnWidth

    // Sections in the order orka-keys lists them, filtered by the search text.
    readonly property var sections: {
        const q = query.trim().toLowerCase();
        const order = [];
        const bySection = {};
        for (const r of rows) {
            if (q !== "" && !(r.keys + " " + r.description + " " + r.section).toLowerCase().includes(q))
                continue;
            if (!(r.section in bySection)) {
                bySection[r.section] = [];
                order.push(r.section);
            }
            bySection[r.section].push(r);
        }
        return order.map(name => ({ name: name, items: bySection[name] }));
    }

    // Spread the sections over the columns, each into the shortest column so far.
    function distribute(secs, count) {
        const cols = [];
        for (let i = 0; i < count; i++)
            cols.push({ height: 0, sections: [] });
        for (const s of secs) {
            let best = cols[0];
            for (const c of cols)
                if (c.height < best.height)
                    best = c;
            best.sections.push(s);
            best.height += s.items.length + 2;
        }
        return cols.map(c => c.sections);
    }

    function show() {
        query = "";
        error = "";
        loading = true;
        open = true;
        loader.running = true;
    }

    Process {
        id: loader
        command: ["orka-keys"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.rows = JSON.parse(text);
                } catch (e) {
                    root.error = "Could not read the key bindings (orka-keys): " + e;
                }
                root.loading = false;
            }
        }
        onExited: code => {
            if (code !== 0) {
                root.error = "orka-keys failed (exit code " + code + ")";
                root.loading = false;
            }
        }
    }

    IpcHandler {
        target: "cheatsheet"

        function toggle(): void {
            if (root.open)
                root.open = false;
            else
                root.show();
        }
        function open(): void {
            root.show();
        }
        function close(): void {
            root.open = false;
        }
    }

    PanelWindow {
        screen: Quickshell.screens.find(s => Hyprland.focusedMonitor && s.name === Hyprland.focusedMonitor.name) ?? Quickshell.screens[0]
        visible: root.open
        onVisibleChanged: {
            if (visible) {
                search.text = "";
                flick.contentY = 0;
                Qt.callLater(() => search.forceActiveFocus());
            }
        }

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "orka-cheatsheet"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        color: "#99000000"

        MouseArea {
            anchors.fill: parent
            onClicked: root.open = false
        }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: Math.round(parent.width * 0.92)
            height: Math.round(parent.height * 0.9)
            color: Theme.background
            border.width: 2
            border.color: Theme.accent

            MouseArea {
                anchors.fill: parent   // clicks inside don't close it
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Text {
                        text: "Keyboard shortcuts"
                        color: Theme.foreground
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize + 6
                        font.bold: true
                    }

                    // Search field.
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 32
                        color: "transparent"
                        border.width: 1
                        border.color: search.activeFocus ? Theme.accent : Qt.alpha(Theme.foreground, 0.3)

                        TextInput {
                            id: search
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.foreground
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize + 1
                            clip: true
                            focus: true
                            onTextChanged: {
                                root.query = text;
                                flick.contentY = 0;
                            }
                            Keys.onEscapePressed: {
                                if (text !== "")
                                    text = "";
                                else
                                    root.open = false;
                            }
                            Keys.onUpPressed: flick.scrollBy(-60)
                            Keys.onDownPressed: flick.scrollBy(60)
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_PageUp) {
                                    flick.scrollBy(-flick.height * 0.9);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_PageDown) {
                                    flick.scrollBy(flick.height * 0.9);
                                    event.accepted = true;
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: search.text === ""
                                text: "Type to search, e.g. \"tmux\", \"SUPER + SHIFT\" or \"screenshot\""
                                color: Theme.foreground
                                opacity: 0.4
                                font: search.font
                            }
                        }
                    }

                    Text {
                        text: "Esc to close"
                        color: Theme.foreground
                        opacity: 0.5
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.loading || root.error !== "" || root.sections.length === 0
                    text: root.loading ? "Reading the key bindings..."
                        : root.error !== "" ? root.error
                        : "Nothing matches \"" + root.query + "\""
                    color: root.error !== "" ? Theme.urgent : Theme.foreground
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 1
                }

                Flickable {
                    id: flick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width
                    contentHeight: columns.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    function scrollBy(dy) {
                        contentY = Math.max(0, Math.min(contentHeight - height, contentY + dy));
                    }

                    onWidthChanged: {
                        root.columnCount = Math.max(1, Math.floor((width + root.gap) / (root.minColumnWidth + root.gap)));
                        root.columnWidth = Math.floor((width - root.gap * (root.columnCount - 1)) / root.columnCount);
                    }

                    Row {
                        id: columns
                        spacing: root.gap

                        Repeater {
                            model: root.distribute(root.sections, root.columnCount)

                            Column {
                                required property var modelData
                                width: root.columnWidth
                                spacing: 22

                                Repeater {
                                    model: parent.modelData

                                    Column {
                                        required property var modelData
                                        width: root.columnWidth
                                        spacing: 6

                                        Text {
                                            text: parent.modelData.name
                                            color: Theme.accent
                                            font.family: Theme.font
                                            font.pixelSize: Theme.fontSize + 2
                                            font.bold: true
                                        }

                                        Repeater {
                                            model: parent.modelData.items

                                            RowLayout {
                                                required property var modelData
                                                width: root.columnWidth
                                                spacing: 12

                                                Text {
                                                    Layout.preferredWidth: Math.round(root.columnWidth * 0.46)
                                                    Layout.alignment: Qt.AlignTop
                                                    text: parent.modelData.keys
                                                    color: Theme.foreground
                                                    font.family: Theme.font
                                                    font.pixelSize: Theme.fontSize
                                                    font.bold: true
                                                    wrapMode: Text.Wrap
                                                }
                                                Text {
                                                    Layout.fillWidth: true
                                                    Layout.alignment: Qt.AlignTop
                                                    text: parent.modelData.description
                                                    color: Theme.foreground
                                                    opacity: 0.8
                                                    font.family: Theme.font
                                                    font.pixelSize: Theme.fontSize
                                                    wrapMode: Text.Wrap
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
