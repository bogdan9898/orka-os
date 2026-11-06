pragma Singleton
// The notification daemon (org.freedesktop.Notifications): receives
// notifications and decides which are shown as popups (notifications/Popups.qml).
//
// A popup disappears after its timeout but the notification is kept (up to
// `keep`), so `restore` can bring the latest one back. Do not disturb keeps
// everything except critical notifications from popping up.
//
// Controlled from Hyprland key bindings through `orka-notifications <command>`
// (IPC target "notifications", see the IpcHandler below).
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool dnd: false
    property var popups: []        // shown now, newest first
    property var hidden: []        // timed out or silenced, oldest first
    property bool paused: false    // the mouse is over a popup: timeouts wait

    readonly property int defaultTimeout: 5000   // ms
    readonly property int maxPopups: 5
    readonly property int keep: 20

    property var deadlines: ({})   // notification id -> time (ms) its popup closes

    NotificationServer {
        keepOnReload: true
        persistenceSupported: true
        actionsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true;
            n.closed.connect(() => root.forget(n));
            if (root.dnd && n.urgency !== NotificationUrgency.Critical)
                root.hidden = root.hidden.concat([n]);
            else
                root.show(n);
            root.trim();
        }
    }

    function show(n) {
        // The app's requested timeout, in ms as sent (0 or -1: none given).
        if (n.urgency === NotificationUrgency.Critical)
            delete deadlines[n.id];
        else
            deadlines[n.id] = Date.now() + (n.expireTimeout > 0 ? n.expireTimeout : defaultTimeout);
        popups = [n].concat(popups.filter(x => x !== n));
        // Too many on screen: the oldest go to the hidden list.
        while (popups.length > maxPopups)
            hide(popups[popups.length - 1]);
    }

    function hide(n) {
        popups = popups.filter(x => x !== n);
        hidden = hidden.filter(x => x !== n).concat([n]);
        delete deadlines[n.id];
    }

    function forget(n) {
        popups = popups.filter(x => x !== n);
        hidden = hidden.filter(x => x !== n);
        delete deadlines[n.id];
    }

    // Keep only the latest `keep` hidden notifications.
    function trim() {
        while (hidden.length > keep)
            hidden[0].expire();
    }

    // The default action (clicking the popup), or the only action there is.
    function invoke(n, action) {
        const a = action ?? n.actions.find(x => x.identifier === "default") ?? (n.actions.length === 1 ? n.actions[0] : null);
        if (a)
            a.invoke();
        // Apps may keep "resident" notifications open after an action; others close.
        Qt.callLater(() => {
            if (!n.resident && (popups.includes(n) || hidden.includes(n)))
                n.dismiss();
        });
    }

    Timer {
        interval: 250
        repeat: true
        running: root.popups.length > 0
        onTriggered: {
            const now = Date.now();
            for (const n of root.popups.slice()) {
                const t = root.deadlines[n.id];
                if (t === undefined)
                    continue;
                if (root.paused)
                    root.deadlines[n.id] = t + interval;
                else if (t <= now)
                    root.hide(n);
            }
        }
    }

    IpcHandler {
        target: "notifications"

        function dismiss(): void {
            if (root.popups.length)
                root.popups[0].dismiss();
        }
        function dismissAll(): void {
            for (const n of root.popups.slice())
                n.dismiss();
        }
        function invoke(): void {
            if (root.popups.length)
                root.invoke(root.popups[0]);
        }
        function restore(): void {
            if (root.hidden.length)
                root.show(root.hidden[root.hidden.length - 1]);
            root.hidden = root.hidden.filter(x => !root.popups.includes(x));
        }
        function toggleDnd(): string {
            root.dnd = !root.dnd;
            return root.dnd ? "on" : "off";
        }
        function status(): string {
            return "dnd=" + (root.dnd ? "on" : "off") + " shown=" + root.popups.length + " hidden=" + root.hidden.length;
        }
    }
}
