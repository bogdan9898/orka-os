// Bell with a slash while do not disturb is on (SUPER + CTRL + ,); click
// to turn it off.
import QtQuick
import qs

BarIcon {
    visible: Notifications.dnd
    text: Theme.icons.dnd
    onClicked: Notifications.dnd = false
}
