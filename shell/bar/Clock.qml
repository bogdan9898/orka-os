// "10 Nov 2026 Tuesday 3:42 PM"; click: the calendar under it.
import QtQuick
import Quickshell
import qs

BarIcon {
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    text: Qt.formatDateTime(clock.date, "d MMM yyyy dddd h:mm AP")
    onClicked: CalendarState.open = !CalendarState.open
}
