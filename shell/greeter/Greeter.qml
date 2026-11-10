// The login screen: clock, user, password; Enter logs in and starts Hyprland
// (through uwsm, like the hyprland-uwsm session). Reboot and shut down
// buttons at the bottom.
// After the password the greeter shows the boot screen's ripples for at least
// minShowMs (a smooth hand-over instead of a flash), and longer if the boot
// hasn't finished yet (see bootDone below), so uwsm doesn't have to wait on
// the bare text console with its "graphical.target is queued" text.
// Transitions: the screen fades in from black (what is on the screen before
// it), the password form crossfades into "Welcome", and at the end everything
// fades to black (the screen is black between the greeter and Hyprland), so
// no hand-over is a hard cut.
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import qs
import qs.polkit

FloatingWindow {
    id: root
    color: Theme.background

    // The session greetd starts after a successful login.
    // orka-session (bin/): clears the console and starts Hyprland through
    // uwsm without its progress text. One word: greetd joins the command's
    // words with spaces and runs them through a shell.
    readonly property var session: ["orka-session"]
    readonly property var sessionEnv: ["XDG_SESSION_TYPE=wayland", "XDG_CURRENT_DESKTOP=Hyprland", "XDG_SESSION_DESKTOP=Hyprland"]

    property var users: []
    property var fullNames: ({})   // user -> full name from /etc/passwd ("" if not set)
    // For "Welcome, ...": the full name, else the login name capitalized.
    function displayName(u) {
        return fullNames[u] || (u ? u.charAt(0).toUpperCase() + u.substring(1) : "");
    }
    property int userIndex: 0
    readonly property string user: users.length ? users[userIndex] : ""
    property string password: ""
    property bool busy: false
    property string status: ""
    property bool statusIsError: false
    // Logged in, waiting for the boot to finish before starting the session.
    property bool starting: false
    property real startedAt: 0
    // 0..1, the ripples' 2 s cycle (as on the boot screen).
    property real ripplePhase: 0
    // Longest wait for the boot; after it the session starts anyway (uwsm
    // then waits out the rest itself, with its text).
    readonly property int maxWaitMs: 20000
    // Shortest time the ripples show (fade to black included), even when the
    // boot is long done.
    readonly property int minShowMs: 3000
    // Fading to black before the session starts; no more polling meanwhile.
    property bool leaving: false

    // Transition times (ms).
    readonly property int fadeInMs: 600      // the screen, from black
    readonly property int formOutMs: 250     // password form out...
    readonly property int welcomeInMs: 450   // ...then "Welcome" in
    readonly property int fadeOutMs: 500     // to black, then the session

    function login() {
        if (busy || user === "")
            return;
        busy = true;
        status = "";
        Greetd.createSession(user);
    }

    function failed(message) {
        // Also after a failed session start: back from black to the form.
        fadeOut.stop();
        veil.opacity = 0;
        leaving = false;
        starting = false;
        busy = false;
        password = "";
        passwordInput.text = "";
        status = message;
        statusIsError = true;
        passwordInput.forceActiveFocus();
    }

    // uwsm (start) waits while graphical.target has a start job queued, and
    // prints that on the text console. Wait for the same here: done when the
    // target is active or no longer queued.
    Process {
        id: bootDone
        command: ["sh", "-c", "systemctl is-active -q graphical.target || ! systemctl list-jobs --no-legend graphical.target | grep -q ."]
        onExited: exitCode => {
            if (!root.starting || root.leaving)
                return;
            const waited = Date.now() - root.startedAt;
            if (exitCode === 0) {
                if (waited >= root.minShowMs - root.fadeOutMs)
                    root.leave();
            } else if (waited >= root.maxWaitMs) {
                console.warn("orka greeter: graphical.target not reached after " + root.maxWaitMs / 1000 + " s, starting the session anyway");
                root.leave();
            }
        }
    }

    Timer {
        id: bootPoll
        interval: 500
        repeat: true
        triggeredOnStart: true
        running: root.starting && !root.leaving
        onTriggered: {
            if (!bootDone.running)
                bootDone.running = true;
        }
    }

    NumberAnimation on ripplePhase {
        from: 0
        to: 1
        duration: 2000
        loops: Animation.Infinite
        running: root.starting
    }

    // Fade to black, then start the session (the greeter quits with it).
    function leave() {
        leaving = true;
        fadeOut.start();
    }

    function launchSession() {
        console.info("orka greeter: starting the session");
        Greetd.launch(session, sessionEnv, true);
    }

    // Normal users: UID 1000-59999 with a real login shell.
    Process {
        running: true
        // name:full name (the comment field up to its first comma).
        command: ["awk", "-F:", "$3 >= 1000 && $3 < 60000 && $7 !~ /(nologin|false)$/ { split($5, f, \",\"); print $1 \":\" f[1] }", "/etc/passwd"]
        stdout: StdioCollector {
            onStreamFinished: {
                const names = {};
                const users = [];
                for (const line of text.split("\n")) {
                    if (line === "")
                        continue;
                    const i = line.indexOf(":");
                    users.push(line.substring(0, i));
                    names[line.substring(0, i)] = line.substring(i + 1).trim();
                }
                root.fullNames = names;
                root.users = users;
            }
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
            console.info("orka greeter: logged in, waiting for the boot to finish");
            root.status = "";
            root.startedAt = Date.now();
            root.starting = true;
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

        // The password form and, after the login, "Welcome" with the ripples
        // share this slot (the clock stays put): the form fades out, then
        // "Welcome" fades in and rises a little.
        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: Math.max(form.implicitWidth, ripples.implicitWidth)
            implicitHeight: Math.max(form.implicitHeight, ripples.implicitHeight)

            ColumnLayout {
                id: form
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10
                opacity: root.starting ? 0 : 1
                visible: opacity > 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: root.formOutMs
                        easing.type: Easing.OutCubic
                    }
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

                // "Wrong password" and other messages, under the field.
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

            // While waiting for the boot: "Welcome, <name>" with ripples spreading
            // below it, like the boot screen (branding/plymouth/orka/orka.script):
            // three flat rings, each growing while it fades, a third of a cycle
            // apart.
            Item {
                id: ripples
                anchors.horizontalCenter: parent.horizontalCenter
                implicitWidth: Math.max(200, welcome.implicitWidth, startingText.implicitWidth)
                implicitHeight: 165
                opacity: root.starting ? 1 : 0
                visible: opacity > 0
                transform: Translate {
                    y: (1 - ripples.opacity) * 16
                }
                // In after the form is out; out at once (only after a failed start).
                Behavior on opacity {
                    SequentialAnimation {
                        PauseAnimation {
                            duration: root.starting ? root.formOutMs : 0
                        }
                        NumberAnimation {
                            duration: root.starting ? root.welcomeInMs : root.formOutMs
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                readonly property real fullWidth: 130
                readonly property real centerY: 100

                Text {
                    id: welcome
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 10
                    text: "Welcome, " + root.displayName(root.user)
                    color: Theme.foreground
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 14
                    font.bold: true
                }

                Repeater {
                    model: 3
                    Shape {
                        id: ring
                        required property int index
                        readonly property real p: (root.ripplePhase + index / 3) % 1
                        readonly property real w: ripples.fullWidth * (0.2 + p)
                        anchors.fill: parent
                        opacity: 0.9 * (1 - p)
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            strokeColor: Theme.accent
                            strokeWidth: 2
                            fillColor: "transparent"
                            PathAngleArc {
                                centerX: ripples.width / 2
                                centerY: ripples.centerY
                                radiusX: ring.w / 2
                                radiusY: ring.w / 2 * 0.24
                                startAngle: 0
                                sweepAngle: 360
                            }
                        }
                    }
                }

                Text {
                    id: startingText
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 140
                    text: "Starting the desktop..."
                    color: Theme.foreground
                    opacity: 0.7
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                }
            }
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

    // Black over everything: fades out at the start (the screen fades in from
    // black) and back in before the session starts. Takes no mouse input.
    Rectangle {
        id: veil
        anchors.fill: parent
        z: 100
        color: "black"
        opacity: 1
        NumberAnimation on opacity {
            to: 0
            duration: root.fadeInMs
            easing.type: Easing.OutCubic
        }
    }

    NumberAnimation {
        id: fadeOut
        target: veil
        property: "opacity"
        to: 1
        duration: root.fadeOutMs
        easing.type: Easing.InOutCubic
        onFinished: root.launchSession()
    }

    Component.onCompleted: passwordInput.forceActiveFocus()
}
