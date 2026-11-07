// The login screen: clock, user, password; Enter logs in and starts Hyprland
// (through uwsm, like the hyprland-uwsm session). Reboot and shut down
// buttons at the bottom.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import qs
import qs.polkit

FloatingWindow {
    id: root
    color: Theme.background

    // The session greetd starts after a successful login.
    readonly property var session: ["uwsm", "start", "-e", "-D", "Hyprland", "hyprland.desktop"]
    readonly property var sessionEnv: ["XDG_SESSION_TYPE=wayland", "XDG_CURRENT_DESKTOP=Hyprland", "XDG_SESSION_DESKTOP=Hyprland"]

    property var users: []
    property int userIndex: 0
    readonly property string user: users.length ? users[userIndex] : ""
    property string password: ""
    property bool busy: false
    property string status: ""
    property bool statusIsError: false

    function login() {
        if (busy || user === "")
            return;
        busy = true;
        status = "";
        Greetd.createSession(user);
    }

    function failed(message) {
        busy = false;
        password = "";
        passwordInput.text = "";
        status = message;
        statusIsError = true;
        passwordInput.forceActiveFocus();
    }

    // Normal users: UID 1000-59999 with a real login shell.
    Process {
        running: true
        command: ["awk", "-F:", "$3 >= 1000 && $3 < 60000 && $7 !~ /(nologin|false)$/ { print $1 }", "/etc/passwd"]
        stdout: StdioCollector {
            onStreamFinished: root.users = text.split("\n").filter(u => u !== "")
        }
    }

    Connections {
        target: Greetd
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            console.info("orka greeter: auth message, response required: " + responseRequired);
            if (responseRequired) {
                Greetd.respond(root.password);
                root.password = "";
            } else if (message !== "") {
                root.status = message;
                root.statusIsError = error;
            }
        }
        function onAuthFailure(message) {
            console.info("orka greeter: auth failure: " + message);
            root.failed("Wrong password");
        }
        function onReadyToLaunch() {
            console.info("orka greeter: logged in, starting the session");
            root.status = "Starting the desktop...";
            root.statusIsError = false;
            Greetd.launch(root.session, root.sessionEnv, true);
        }
        function onError(error) {
            console.warn("orka greeter: greetd error: " + error);
            // After a failed login greetd's session is gone, so Quickshell's
            // follow-up message can fail too; the failure is already shown.
            if (root.busy)
                root.failed("Login failed: " + error);
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    MouseArea {
        anchors.fill: parent
        onClicked: passwordInput.forceActiveFocus()
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

        // User: TAB / the arrows switch when there is more than one.
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10
            Text {
                visible: root.users.length > 1
                text: "‹"
                color: Theme.foreground
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 6
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.userIndex = (root.userIndex + root.users.length - 1) % root.users.length
                }
            }
            Text {
                text: root.user || "no users"
                color: Theme.foreground
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 4
                font.bold: true
            }
            Text {
                visible: root.users.length > 1
                text: "›"
                color: Theme.foreground
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 6
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.userIndex = (root.userIndex + 1) % root.users.length
                }
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 320
            implicitHeight: 40
            color: "transparent"
            border.width: 2
            border.color: root.statusIsError ? Theme.urgent : Theme.accent

            TextInput {
                id: passwordInput
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
                readOnly: root.busy
                focus: true
                clip: true
                onTextChanged: root.password = text
                onAccepted: root.login()
                Keys.onEscapePressed: text = ""
                Keys.onTabPressed: {
                    if (root.users.length > 1)
                        root.userIndex = (root.userIndex + 1) % root.users.length;
                }

                Text {
                    anchors.centerIn: parent
                    visible: passwordInput.text === ""
                    text: root.busy ? "Logging in..." : "Password"
                    color: Theme.foreground
                    opacity: 0.4
                    font: passwordInput.font
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: 480
            visible: text !== ""
            text: root.status
            color: root.statusIsError ? Theme.urgent : Theme.foreground
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // OrkaOS: the badge and the name, bottom left.
    Row {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 24
        spacing: 10
        Image {
            anchors.verticalCenter: parent.verticalCenter
            width: 28
            height: 28
            source: Theme.logoBadge
            sourceSize: Qt.size(84, 84)
            smooth: true
            mipmap: true
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "OrkaOS"
            color: Theme.foreground
            opacity: 0.7
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 2
        }
    }

    RowLayout {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        spacing: 8

        DialogButton {
            text: "Reboot"
            onClicked: Quickshell.execDetached(["systemctl", "reboot"])
        }
        DialogButton {
            text: "Shut down"
            onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
        }
    }

    Component.onCompleted: passwordInput.forceActiveFocus()
}
