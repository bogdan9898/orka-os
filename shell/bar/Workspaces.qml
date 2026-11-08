// Workspaces 1-5 always, plus any other one that has windows. The active
// workspace of this monitor is a filled square, empty ones are dimmed.
// Click to go there, scroll to step through them.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs

RowLayout {
    id: root
    required property ShellScreen screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property int activeId: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : -1
    readonly property var existing: Hyprland.workspaces.values.filter(ws => ws.id > 0).map(ws => ws.id)
    readonly property var ids: [1, 2, 3, 4, 5].concat(existing.filter(id => id > 5)).sort((a, b) => a - b)

    spacing: 0

    // Not named "focus": every Item already has a focus property, which
    // hides a function of that name (clicks did nothing).
    function goTo(target) {
        Hyprland.dispatch("hl.dsp.focus({ workspace = \"" + target + "\" })");
    }

    Repeater {
        model: root.ids

        BarIcon {
            required property int modelData
            text: modelData === root.activeId ? Theme.icons.workspace : String(modelData % 10)
            opacity: root.existing.includes(modelData) ? 1 : 0.5
            leftPadding: 6
            rightPadding: 6
            onClicked: root.goTo(modelData)
            onScrolled: steps => root.goTo(steps > 0 ? "e-1" : "e+1")
        }
    }
}
