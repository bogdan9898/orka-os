pragma Singleton
// Whether the settings app is open and on which page, plus its IPC target
// "settings": `qs -p /usr/share/orka/shell ipc call settings toggle|open|close`
// (SUPER + ALT + SPACE, the "OrkaOS Settings" launcher entry, a right click on
// the bar's menu button). `openPage <name>` opens a page directly.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool open: false
    property string page: "theme"

    IpcHandler {
        target: "settings"

        function toggle(): void {
            root.open = !root.open;
        }
        function open(): void {
            root.open = true;
        }
        function close(): void {
            root.open = false;
        }
        // theme wallpaper display idle sound nightlight keyboard about
        function openPage(name: string): void {
            root.page = name;
            root.open = true;
        }
    }
}
