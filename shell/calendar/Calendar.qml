// The calendar that drops down under the bar's clock (on the focused
// monitor). A month at a time, weeks start on Monday, ISO week numbers on
// the left, today filled with the accent color.
// Arrows ‹ › / scroll / Left Right / Page Up Down: previous or next month.
// Clicking the month's name switches to the month picker (a year at a time,
// the same arrows change the year; pick a month, click the year or press
// Escape to go back to the days). The "Today" button or Home: back to today.
// Escape (on the days), a click outside or SUPER + W closes it. Opening it closes the
// notification center and the other way round (both sit under the bar).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs
import qs.polkit

PanelWindow {
    id: window

    screen: Quickshell.screens.find(s => Hyprland.focusedMonitor && s.name === Hyprland.focusedMonitor.name) ?? Quickshell.screens[0]
    visible: CalendarState.open

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    // Below the bar (its exclusive zone), so the clock still toggles it.
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "orka-calendar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: "transparent"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes   // "today" moves on at midnight
    }
    readonly property date today: clock.date

    // The month on show: its year and month (0 = January).
    property int year: today.getFullYear()
    property int month: today.getMonth()
    readonly property bool showingToday: year === today.getFullYear() && month === today.getMonth()
    property bool picking: false   // the month picker instead of the days

    function goToday() {
        year = today.getFullYear();
        month = today.getMonth();
        picking = false;
    }
    // One step back (-1) or forward: a month on the days, a year in the picker.
    function step(n) {
        const m = year * 12 + month + (picking ? 12 * n : n);
        year = Math.floor(m / 12);
        month = m - year * 12;
    }

    // ISO 8601 week number (week 1 has the year's first Thursday).
    function isoWeek(date) {
        const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
        d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
        const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
        return Math.ceil(((d - yearStart) / 86400000 + 1) / 7);
    }

    // Always six weeks from the Monday on or before the 1st, so the box
    // keeps its size from month to month.
    readonly property var days: {
        const first = new Date(year, month, 1);
        const start = new Date(year, month, 1 - (first.getDay() + 6) % 7);
        const list = [];
        for (let i = 0; i < 42; i++)
            list.push(new Date(start.getFullYear(), start.getMonth(), start.getDate() + i));
        return list;
    }

    // Opens on today's month, with a short fade and drop (Settings →
    // Animations: off, and its speed).
    property real shown: 1
    NumberAnimation {
        id: showAnimation
        target: window
        property: "shown"
        from: 0
        to: 1
        duration: Math.round(150 * Settings.animationSpeed)
        easing.type: Easing.OutCubic
    }
    onVisibleChanged: {
        if (!visible)
            return;
        goToday();
        Notifications.centerOpen = false;
        if (Settings.animationsOn)
            showAnimation.restart();
        Qt.callLater(() => box.forceActiveFocus());
    }

    // A click outside the box closes it.
    MouseArea {
        anchors.fill: parent
        onClicked: CalendarState.open = false
    }

    readonly property int cell: Math.round(Theme.fontSize * 2.5)

    Rectangle {
        id: box
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 8
        width: content.implicitWidth + 2 * 16
        height: content.implicitHeight + 2 * 14
        color: Theme.background
        border.width: 2
        border.color: Theme.accent
        opacity: window.shown
        transform: Translate {
            y: (window.shown - 1) * 10
        }

        focus: true
        Keys.onEscapePressed: {
            if (window.picking)
                window.picking = false;
            else
                CalendarState.open = false;
        }
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Left || event.key === Qt.Key_PageUp)
                window.step(-1);
            else if (event.key === Qt.Key_Right || event.key === Qt.Key_PageDown)
                window.step(1);
            else if (event.key === Qt.Key_Home)
                window.goToday();
            else
                return;
            event.accepted = true;
        }

        MouseArea {
            anchors.fill: parent   // clicks inside don't close it
            property real wheel: 0
            onWheel: event => {
                wheel += event.angleDelta.y;
                while (Math.abs(wheel) >= 120) {
                    window.step(wheel > 0 ? -1 : 1);
                    wheel -= wheel > 0 ? 120 : -120;
                }
            }
        }

        ColumnLayout {
            id: content
            anchors.centerIn: parent
            spacing: 10

            // ‹  November 2026  [Today]  ›   (the picker: ‹  2026  [Today]  ›)
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                NavArrow {
                    text: "‹"
                    onClicked: window.step(-1)
                }
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: window.picking ? window.year : Qt.locale().standaloneMonthName(window.month) + " " + window.year
                    color: titleArea.containsMouse ? Theme.accent : Theme.foreground
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 2
                    font.bold: true
                    MouseArea {
                        id: titleArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.picking = !window.picking
                    }
                }
                DialogButton {
                    visible: !window.showingToday || window.picking
                    text: "Today"
                    onClicked: window.goToday()
                }
                NavArrow {
                    text: "›"
                    onClicked: window.step(1)
                }
            }

            // The days and the month picker share one place, the size of the days.
            Item {
                implicitWidth: dayGrid.implicitWidth
                implicitHeight: dayGrid.implicitHeight

                // Week number column, then Monday to Sunday.
                GridLayout {
                    id: dayGrid
                    visible: !window.picking
                    columns: 8
                    rowSpacing: 2
                    columnSpacing: 2

                    Text {
                        Layout.preferredWidth: window.cell
                        horizontalAlignment: Text.AlignHCenter
                        text: "W"
                        color: Theme.accent
                        opacity: 0.7
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                    }
                    Repeater {
                        // Qt's day numbers: 1 = Monday … 7 = Sunday.
                        model: [1, 2, 3, 4, 5, 6, 7]
                        Text {
                            required property int modelData
                            Layout.preferredWidth: window.cell
                            horizontalAlignment: Text.AlignHCenter
                            text: Qt.locale().dayName(modelData % 7, Locale.ShortFormat).slice(0, 2)
                            color: Theme.foreground
                            opacity: modelData >= 6 ? 0.5 : 0.75
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                            font.bold: true
                        }
                    }

                    Repeater {
                        model: 6 * 8
                        Item {
                            id: slot
                            required property int index
                            readonly property bool weekColumn: index % 8 === 0
                            readonly property date day: window.days[Math.floor(index / 8) * 7 + index % 8 - (weekColumn ? 0 : 1)]
                            readonly property bool inMonth: day.getMonth() === window.month
                            readonly property bool isToday: day.getFullYear() === window.today.getFullYear()
                                && day.getMonth() === window.today.getMonth() && day.getDate() === window.today.getDate()
                            readonly property bool weekend: day.getDay() === 0 || day.getDay() === 6

                            Layout.preferredWidth: window.cell
                            Layout.preferredHeight: window.cell

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: width / 2
                                visible: slot.isToday && !slot.weekColumn
                                color: Theme.accent
                            }
                            Text {
                                anchors.centerIn: parent
                                text: slot.weekColumn ? window.isoWeek(slot.day) : slot.day.getDate()
                                color: slot.weekColumn ? Theme.accent : Theme.foreground
                                opacity: slot.weekColumn ? 0.7
                                    : slot.isToday ? 1
                                    : !slot.inMonth ? 0.3
                                    : slot.weekend ? 0.6 : 1
                                font.family: Theme.font
                                font.pixelSize: slot.weekColumn ? Theme.fontSize - 1 : Theme.fontSize
                                font.bold: slot.isToday
                            }
                        }
                    }
                }

                // The month picker: the year's twelve months; today's month
                // filled, the one on show outlined.
                GridLayout {
                    anchors.fill: parent
                    visible: window.picking
                    columns: 3
                    rowSpacing: 6
                    columnSpacing: 6

                    Repeater {
                        model: 12
                        Item {
                            id: monthCell
                            required property int index
                            readonly property bool isToday: window.year === window.today.getFullYear() && index === window.today.getMonth()
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Rectangle {
                                anchors.centerIn: parent
                                width: monthLabel.implicitWidth + 28
                                height: window.cell
                                radius: height / 2
                                color: monthCell.isToday ? Theme.accent : "transparent"
                                border.width: monthArea.containsMouse || monthCell.index === window.month ? 1 : 0
                                border.color: Theme.accent
                            }
                            Text {
                                id: monthLabel
                                anchors.centerIn: parent
                                text: Qt.locale().standaloneMonthName(monthCell.index, Locale.ShortFormat)
                                color: Theme.foreground
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize
                                font.bold: monthCell.isToday
                            }
                            MouseArea {
                                id: monthArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    window.month = monthCell.index;
                                    window.picking = false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component NavArrow: Text {
        id: arrow
        signal clicked
        Layout.preferredWidth: window.cell
        horizontalAlignment: Text.AlignHCenter
        color: arrowArea.containsMouse ? Theme.accent : Theme.foreground
        font.family: Theme.font
        font.pixelSize: Theme.fontSize + 6
        MouseArea {
            id: arrowArea
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: arrow.clicked()
        }
    }
}
