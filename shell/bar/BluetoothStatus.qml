// Bluetooth: off, on, or a device connected. Click: bluetui.
// Hidden when the machine has no Bluetooth adapter.
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs

BarIcon {
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter !== null && adapter.enabled
    readonly property bool connected: Bluetooth.devices.values.some(d => d.connected)

    visible: adapter !== null
    text: !on ? Theme.icons.btOff : connected ? Theme.icons.btConnected : Theme.icons.btOn
    onClicked: Apps.tui("bluetui")
}
