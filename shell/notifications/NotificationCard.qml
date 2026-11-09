// One notification popup. Click: default action (or close), right click:
// close, buttons: the app's other actions. In the notification center
// (inCenter) it also shows when it arrived and a close button.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs

Rectangle {
    id: card
    required property Notification modelData
    readonly property Notification n: modelData
    readonly property bool critical: n.urgency === NotificationUrgency.Critical
    readonly property var buttons: n.actions.filter(a => a.identifier !== "default")

    property bool inCenter: false
    property real now: Date.now()   // the center ticks this, for "5 min ago"

    function age(t) {
        if (!t)
            return "";
        const min = Math.floor((now - t) / 60000);
        if (min < 1)
            return "just now";
        if (min < 60)
            return min + " min ago";
        const h = Math.floor(min / 60);
        return h < 24 ? h + " h ago" : Qt.formatDateTime(new Date(t), "d MMM HH:mm");
    }

    // An image sent with the notification, else the app's icon; nothing if
    // neither exists (instead of Qt's checkerboard for a missing icon).
    function resolve(src) {
        if (!src)
            return "";
        if (src.startsWith("image://icon/"))   // notify-send -i <name> sends this as the image
            return Quickshell.iconPath(src.substring(13), true);
        if (src.startsWith("/"))
            return "file://" + src;
        if (src.includes("://"))   // file:// or raw image data from the app
            return src;
        return Quickshell.iconPath(src, true);   // an icon name
    }
    readonly property string picture: resolve(n.image) || resolve(n.appIcon)
    // A picture worth seeing, not an icon (orka-screenshot sends the hint
    // x-orka-preview): shown large under the text instead of the 40 px icon.
    readonly property bool preview: picture !== "" && n.hints["x-orka-preview"] === true

    implicitHeight: content.implicitHeight + 24
    color: Theme.background
    border.width: 2
    border.color: critical ? Theme.urgent : Theme.accent

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onContainsMouseChanged: Notifications.paused = containsMouse
        onClicked: mouse => mouse.button === Qt.RightButton ? card.n.dismiss() : Notifications.invoke(card.n)
    }

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        IconImage {
            visible: card.picture !== "" && !card.preview
            source: card.picture
            implicitSize: 40
            Layout.alignment: Qt.AlignTop
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: card.n.summary || card.n.appName
                    color: Theme.foreground
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 1
                    font.bold: true
                    elide: Text.ElideRight
                }
                Text {
                    visible: card.inCenter
                    text: card.age(Notifications.receivedAt[card.n.id])
                    color: Theme.foreground
                    opacity: 0.6
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                }
                Text {
                    visible: card.inCenter
                    text: Theme.icons.close
                    color: closeArea.containsMouse ? Theme.urgent : Theme.foreground
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 2
                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.n.dismiss()
                    }
                }
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: card.n.body
                textFormat: Text.StyledText   // the <b>, <i>, <u>, <a> subset apps may use
                color: Theme.foreground
                opacity: 0.85
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                wrapMode: Text.Wrap
                maximumLineCount: 6
                elide: Text.ElideRight
                onLinkActivated: link => Qt.openUrlExternally(link)
            }
            Image {
                id: previewImage
                visible: card.preview
                Layout.fillWidth: true
                Layout.topMargin: 4
                // The picture's shape, at most 160 px high.
                Layout.preferredHeight: visible && implicitWidth > 0 ? Math.min(160, width * implicitHeight / implicitWidth) : 0
                source: card.preview ? card.picture : ""
                sourceSize.width: 712
                fillMode: Image.PreserveAspectFit
                horizontalAlignment: Image.AlignLeft
                asynchronous: true
                cache: false
            }
            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 4
                visible: card.buttons.length > 0
                spacing: 6

                Repeater {
                    model: card.buttons

                    Rectangle {
                        required property NotificationAction modelData
                        implicitWidth: label.implicitWidth + 16
                        implicitHeight: label.implicitHeight + 8
                        color: buttonArea.containsMouse ? Theme.accent : "transparent"
                        border.width: 1
                        border.color: Theme.accent

                        Text {
                            id: label
                            anchors.centerIn: parent
                            text: parent.modelData.text
                            color: Theme.foreground
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                        }
                        MouseArea {
                            id: buttonArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Notifications.invoke(card.n, parent.modelData)
                        }
                    }
                }
            }
        }
    }
}
