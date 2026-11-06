// The polkit agent: when an app needs admin rights (GParted, mounting a disk
// in Dolphin, `pkexec` from a launcher...), polkit asks us for the password.
// Shows a dialog on the focused monitor that takes all keyboard input until
// it's answered: Enter authenticates, Escape cancels. A wrong password
// clears the field and asks again.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Polkit
import Quickshell.Wayland
import qs

Scope {
    id: root
    readonly property AuthFlow flow: agent.flow
    property bool checking: false   // password sent, waiting for the answer
    property bool wrong: false      // the last password was wrong

    PolkitAgent {
        id: agent
        path: "/org/orka/PolkitAgent"
        onAuthenticationRequestStarted: {
            root.checking = false;
            root.wrong = false;
            input.text = "";
            Qt.callLater(() => input.forceActiveFocus());
        }
        onIsRegisteredChanged: console.info(isRegistered ? "orka: polkit agent registered"
            : "orka: polkit agent not registered (is another agent running?)")
    }

    Connections {
        target: root.flow
        function onAuthenticationFailed() {
            root.checking = false;
            root.wrong = true;
            input.text = "";
            input.forceActiveFocus();
        }
        function onIsResponseRequiredChanged() {
            if (root.flow && root.flow.isResponseRequired) {
                root.checking = false;
                input.forceActiveFocus();
            }
        }
    }

    function submit() {
        if (!flow || !flow.isResponseRequired || checking)
            return;
        checking = true;
        wrong = false;
        flow.submit(input.text);
        input.text = "";
    }

    function cancel() {
        if (flow)
            flow.cancelAuthenticationRequest();
    }

    PanelWindow {
        screen: Quickshell.screens.find(s => Hyprland.focusedMonitor && s.name === Hyprland.focusedMonitor.name) ?? Quickshell.screens[0]
        visible: agent.isActive && root.flow !== null

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "orka-polkit"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        color: "#99000000"   // dims everything behind the dialog

        MouseArea {
            anchors.fill: parent
            onClicked: input.forceActiveFocus()
        }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: 440
            implicitHeight: content.implicitHeight + 48
            color: Theme.background
            border.width: 2
            border.color: root.wrong ? Theme.urgent : Theme.accent

            ColumnLayout {
                id: content
                anchors.fill: parent
                anchors.margins: 24
                spacing: 14

                RowLayout {
                    spacing: 12
                    Text {
                        text: Theme.icons.lock
                        color: Theme.accent
                        font.family: Theme.font
                        font.pixelSize: 28
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "Authentication required"
                        color: Theme.foreground
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize + 4
                        font.bold: true
                    }
                }

                // What the app wants to do, as polkit describes it.
                Text {
                    Layout.fillWidth: true
                    text: root.flow ? root.flow.message : ""
                    color: Theme.foreground
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    wrapMode: Text.Wrap
                }
                Text {
                    Layout.fillWidth: true
                    text: root.flow ? root.flow.actionId : ""
                    color: Theme.foreground
                    opacity: 0.5
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                    elide: Text.ElideMiddle
                }

                // Password field.
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    visible: root.flow !== null && root.flow.isResponseRequired
                    implicitHeight: 36
                    color: "transparent"
                    border.width: 1
                    border.color: input.activeFocus ? Theme.accent : Theme.foreground

                    TextInput {
                        id: input
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.foreground
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize + 1
                        echoMode: root.flow && root.flow.responseVisible ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "•"
                        readOnly: root.checking
                        clip: true
                        focus: true
                        onAccepted: root.submit()
                        Keys.onEscapePressed: root.cancel()

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: input.text === "" && !root.checking
                            text: "Password for " + (Quickshell.env("USER") || "you")
                            color: Theme.foreground
                            opacity: 0.4
                            font: input.font
                        }
                    }
                }

                // Status line: checking, wrong password, or a message from PAM.
                Text {
                    Layout.fillWidth: true
                    readonly property string pam: root.flow ? root.flow.supplementaryMessage : ""
                    visible: text !== ""
                    text: root.checking ? "Checking..."
                        : root.wrong ? "Wrong password, try again"
                        : pam
                    color: root.wrong || (root.flow && root.flow.supplementaryIsError) ? Theme.urgent : Theme.foreground
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    wrapMode: Text.Wrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: 8
                    Item {
                        Layout.fillWidth: true
                    }
                    DialogButton {
                        text: "Cancel"
                        onClicked: root.cancel()
                    }
                    DialogButton {
                        text: "Authenticate"
                        primary: true
                        enabled: root.flow !== null && root.flow.isResponseRequired && !root.checking
                        onClicked: root.submit()
                    }
                }
            }
        }
    }
}
