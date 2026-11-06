// What the lock screen shows on each monitor: clock, date, user and the
// password field. Enter unlocks, Escape clears the field.
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

Item {
    id: surface
    required property var lock   // lock/Lock.qml

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Keep this monitor's field in step with the others.
    Connections {
        target: surface.lock
        function onPasswordChanged() {
            if (input.text !== surface.lock.password)
                input.text = surface.lock.password;
        }
    }

    Component.onCompleted: input.forceActiveFocus()

    MouseArea {
        anchors.fill: parent
        onClicked: input.forceActiveFocus()
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 10

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Theme.foreground
            font.family: Theme.font
            font.pixelSize: 96
            font.bold: true
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
            color: Theme.foreground
            opacity: 0.7
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 6
        }

        Item {
            implicitHeight: 40
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8
            Text {
                text: Theme.icons.lock
                color: Theme.accent
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 4
            }
            Text {
                text: Quickshell.env("USER") || ""
                color: Theme.foreground
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 2
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 320
            implicitHeight: 40
            color: "transparent"
            border.width: 2
            border.color: surface.lock.statusIsError ? Theme.urgent : Theme.accent

            TextInput {
                id: input
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                color: Theme.foreground
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 2
                echoMode: TextInput.Password
                passwordCharacter: "•"
                readOnly: surface.lock.checking
                focus: true
                clip: true
                onTextChanged: surface.lock.password = text
                onAccepted: surface.lock.submit()
                Keys.onEscapePressed: surface.lock.password = ""

                Text {
                    anchors.centerIn: parent
                    visible: input.text === ""
                    text: surface.lock.checking ? "Checking..." : "Password"
                    color: Theme.foreground
                    opacity: 0.4
                    font: input.font
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: 480
            visible: text !== ""
            text: surface.lock.status
            color: surface.lock.statusIsError ? Theme.urgent : Theme.foreground
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
