// The notification center's bell: a bell with a dot when notifications went
// by unseen, a bell with a slash while do not disturb is on. Click: open the
// list (also SUPER + N); right click: toggle do not disturb.
import QtQuick
import qs

BarIcon {
    text: Notifications.dnd ? Theme.icons.dnd : Notifications.missed > 0 ? Theme.icons.bellBadge : Theme.icons.bell
    color: Notifications.missed > 0 && !Notifications.dnd ? Theme.accent : Theme.foreground
    onClicked: Notifications.centerOpen = !Notifications.centerOpen
    onRightClicked: Notifications.dnd = !Notifications.dnd
}
