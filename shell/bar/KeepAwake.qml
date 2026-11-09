// Keep the screen awake: while on (a filled cup in the accent color), idle
// never locks the screen or turns it off (lock/Idle.qml). Click toggles.
// Always off at login (LockState.keepAwake isn't saved).
import QtQuick
import qs

BarIcon {
    text: LockState.keepAwake ? Theme.icons.cupFull : Theme.icons.cup
    color: LockState.keepAwake ? Theme.accent : Theme.foreground
    onClicked: LockState.keepAwake = !LockState.keepAwake
}
