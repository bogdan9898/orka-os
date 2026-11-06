// "Friday 14:05"; click for the date ("06 November W45 2026").
import QtQuick
import Quickshell
import qs

BarIcon {
    id: root
    property bool showDate: false

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // ISO 8601 week number (weeks start on Monday; week 1 has the year's first Thursday).
    function isoWeek(date) {
        const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
        d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
        const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
        return Math.ceil(((d - yearStart) / 86400000 + 1) / 7);
    }

    text: showDate
        ? Qt.formatDateTime(clock.date, "dd MMMM") + " W" + isoWeek(clock.date) + " " + Qt.formatDateTime(clock.date, "yyyy")
        : Qt.formatDateTime(clock.date, "dddd HH:mm")
    onClicked: showDate = !showDate
}
