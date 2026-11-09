pragma Singleton
// Whether the session is locked (lock/Lock.qml does the locking), plus the
// IPC target "lock" used by orka-lock (SUPER + CTRL + L, hypridle before
// sleep). There is deliberately no way to unlock except the password.
// keepAwake: the cup in the bar; while on, idle never locks the screen or
// turns it off (lock/Idle.qml). Not saved: every session starts with it off,
// so a forgotten toggle can't keep an unattended PC unlocked.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool locked: false
    property bool keepAwake: false

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
        function toggleKeepAwake(): string {
            root.keepAwake = !root.keepAwake;
            return root.keepAwake ? "on" : "off";
        }
    }
}
