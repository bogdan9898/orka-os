// A grid of keys from a list: [{ id, label, kind }] (kind as in Key.qml;
// "second": true marks the 2nd switch).
import QtQuick
import QtQuick.Layouts

GridLayout {
    id: grid
    property var keys: []
    rowSpacing: 4
    columnSpacing: 4

    Repeater {
        model: grid.keys
        Key {
            required property var modelData
            Layout.fillWidth: true
            keyId: modelData.id
            label: modelData.label
            kind: modelData.kind || "num"
            on: modelData.id === "second" && calc.second
        }
    }
}
