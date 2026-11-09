// A clickable glyph or label in the bar. tooltip: when the mouse rests on it
// (expandDelay), the item grows to the left and shows this text before the
// glyph; the icon stays under the pointer and the bar's row moves the items
// on its left aside. Collapses as soon as the pointer leaves.
import QtQuick
import qs

Text {
    id: root
    signal clicked
    signal rightClicked
    signal scrolled(int steps)   // +1 per wheel notch up, -1 down
    property string tooltip: ""

    // 0 = just the glyph, 1 = label fully shown (animated).
    property real expand: 0
    readonly property int expandDelay: 400   // a quick point-and-click never expands
    readonly property int gap: 6   // between the label and the glyph
    leftPadding: tooltip !== "" ? Math.round((tipLabel.implicitWidth + gap) * expand) : 0
    Behavior on expand {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }
    }
    Timer {
        id: expandTimer
        interval: root.expandDelay
        onTriggered: root.expand = 1
    }

    // The label, revealed from the glyph leftwards as the padding grows.
    Item {
        visible: root.expand > 0
        width: root.leftPadding
        height: root.height
        clip: true
        Text {
            id: tipLabel
            anchors.right: parent.right
            anchors.rightMargin: root.gap
            anchors.verticalCenter: parent.verticalCenter
            text: root.tooltip
            color: Theme.foreground
            opacity: root.expand
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
        }
    }

    color: Theme.foreground
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    verticalAlignment: Text.AlignVCenter

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4   // a little easier to hit than the glyph itself
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: root.tooltip !== ""
        onEntered: expandTimer.restart()
        onExited: {
            expandTimer.stop();
            root.expand = 0;
        }
        onPressed: expandTimer.stop()   // clicking means it was found
        property real wheel: 0
        onClicked: mouse => mouse.button === Qt.RightButton ? root.rightClicked() : root.clicked()
        onWheel: event => {
            // Touchpads send many small deltas; add them up to whole notches.
            wheel += event.angleDelta.y;
            while (Math.abs(wheel) >= 120) {
                root.scrolled(wheel > 0 ? 1 : -1);
                wheel -= wheel > 0 ? 120 : -120;
            }
        }
    }
}
