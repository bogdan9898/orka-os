pragma Singleton
// Whether the session is locked (lock/Lock.qml does the locking), plus the
// IPC target "lock" used by orka-lock (SUPER + CTRL + L, hypridle before
// sleep). There is deliberately no way to unlock except the password.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool locked: false

    function lock() {
        locked = true;
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lock();
        }
        function status(): string {
            return root.locked ? "locked" : "unlocked";
        }
    }
}
