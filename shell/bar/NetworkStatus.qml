// Network: Wi-Fi signal, wired, or offline. Click: Wi-Fi settings (impala).
// Quickshell's own Networking module only supports NetworkManager; OrkaOS
// uses iwd + systemd-networkd, so this asks orka-netstatus every 5 seconds.
import QtQuick
import Quickshell
import Quickshell.Io
import qs

BarIcon {
    id: root
    property var status: ["offline"]   // orka-netstatus output, split into words

    text: status[0] === "wifi" ? Theme.icons.wifi[Math.min(4, Math.floor(Number(status[1]) / 20))]
        : status[0] === "ethernet" ? Theme.icons.ethernet
        : Theme.icons.offline
    tooltip: status[0] === "wifi" ? "Wi-Fi, signal " + status[1] + "%"
        : status[0] === "ethernet" ? "Ethernet"
        : "Offline"
    onClicked: Apps.tui("impala")

    Process {
        id: check
        command: ["orka-netstatus"]
        stdout: StdioCollector {
            onStreamFinished: root.status = (text.trim() || "offline").split(" ")
        }
    }
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: check.running = true
    }
}
