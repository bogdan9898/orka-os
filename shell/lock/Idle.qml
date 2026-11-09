// Idle: lock the screen and turn the monitors off after the times in
// ~/.config/orka/settings.json (Settings.qml; 0 = never). Apps that inhibit
// idle (a playing video, a call) hold both off, and so does "keep awake"
// (the cup in the bar, LockState.keepAwake): both monitors are removed.
//
// Each IdleMonitor is created anew when its time changes (Instantiator with
// the time as the model): the Wayland idle timer gets its timeout when it's
// created, so changing it on a running monitor has no effect.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs

Scope {
    Instantiator {
        model: Settings.lockAfter > 0 && !LockState.keepAwake ? [Settings.lockAfter] : []

        IdleMonitor {
            required property int modelData
            timeout: modelData
            respectInhibitors: true
            onIsIdleChanged: {
                if (isIdle)
                    LockState.lock();
            }
        }
    }

    Instantiator {
        model: Settings.screenOffAfter > 0 && !LockState.keepAwake ? [Settings.screenOffAfter] : []

        IdleMonitor {
            required property int modelData
            timeout: modelData
            respectInhibitors: true
            onIsIdleChanged: Hyprland.dispatch("hl.dsp.dpms({ action = \"" + (isIdle ? "off" : "on") + "\" })")
        }
    }
}
