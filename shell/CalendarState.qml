pragma Singleton
// Whether the calendar under the bar's clock is open, plus its IPC target
// "calendar": `qs -p /usr/share/orka/shell ipc call calendar toggle|open|close`
// (SUPER + W closes it through `close`).
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool open: false

    IpcHandler {
        target: "calendar"

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
