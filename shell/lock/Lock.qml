// The lock screen: a Wayland session lock (ext-session-lock) with a password
// check through PAM (/etc/pam.d/orka-lock). Locks when LockState.locked is
// set (orka-lock, SUPER + CTRL + L, idle, before sleep); only the right
// password unlocks.
//
// If the shell crashes while locked, Hyprland keeps the session locked
// (misc.allow_session_lock_restore lets a new shell take over), systemd
// restarts the shell (orka-shell.service), and the flag file below makes the
// new shell lock again at once.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs

Scope {
    id: root
    property string password: ""
    property bool checking: false
    property string status: ""
    property bool statusIsError: false

    function reset() {
        password = "";
        checking = false;
        status = "";
        statusIsError = false;
    }

    function submit() {
        if (checking || password === "")
            return;
        checking = true;
        status = "";
        if (!pam.start()) {
            checking = false;
            status = "Could not start the password check (PAM)";
            statusIsError = true;
        }
    }

    // Remember "locked" across a shell restart.
    FileView {
        id: flag
        path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/orka-locked"
        printErrors: false
        onLoaded: {
            if (text().trim() === "locked")
                LockState.locked = true;
        }
    }

    Connections {
        target: LockState
        function onLockedChanged() {
            flag.setText(LockState.locked ? "locked\n" : "");
            root.reset();
        }
    }

    PamContext {
        id: pam
        config: "orka-lock"

        onResponseRequiredChanged: {
            if (responseRequired) {
                respond(root.password);
                root.password = "";
            }
        }
        onPamMessage: {
            // Show what PAM tells us (e.g. "account locked"), but not its "Password:" prompt.
            if (!responseRequired && message !== "") {
                root.status = message;
                root.statusIsError = messageIsError;
            }
        }
        onCompleted: result => {
            root.checking = false;
            if (result === PamResult.Success) {
                LockState.locked = false;
            } else {
                root.password = "";
                if (!root.statusIsError || root.status === "")
                    root.status = "Wrong password";
                root.statusIsError = true;
            }
        }
        onError: error => {
            root.checking = false;
            root.status = "Password check failed: " + PamError.toString(error);
            root.statusIsError = true;
        }
    }

    WlSessionLock {
        locked: LockState.locked

        WlSessionLockSurface {
            color: Theme.background

            LockSurface {
                anchors.fill: parent
                lock: root
            }
        }
    }
}
