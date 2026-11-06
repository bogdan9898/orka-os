pragma Singleton
// Whether the launcher is open, plus its IPC target "launcher" for the
// SUPER + SPACE binding: `qs -p /usr/share/orka/shell ipc call launcher toggle`.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool open: false

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.open = !root.open;
        }
        function open(): void {
            root.open = true;
        }
        function close(): void {
            root.open = false;
        }
    }
}
