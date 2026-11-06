// A horizontal slider. `moved` while dragging, `released` when let go (apply
// expensive changes there). Also arrow keys and the mouse wheel.
import QtQuick
import qs

Item {
    id: root
    property real from: 0
    property real to: 100
    property real stepSize: 1
    property real value: 0
    signal moved(real value)
    signal released(real value)

    implicitWidth: 320
    implicitHeight: 24
    activeFocusOnTab: true

    readonly property real fraction: to > from ? (value - from) / (to - from) : 0

    function setFromX(x) {
        const f = Math.max(0, Math.min(1, x / track.width));
        const v = Math.round((from + f * (to - from)) / stepSize) * stepSize;
        if (v !== value) {
            value = v;
            moved(v);
        }
    }
    function step(n) {
        value = Math.max(from, Math.min(to, value + n * stepSize));
        moved(value);
        released(value);
    }

    Keys.onLeftPressed: step(-1)
    Keys.onRightPressed: step(1)

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        color: Qt.alpha(Theme.foreground, 0.2)

        Rectangle {
            width: parent.width * root.fraction
            height: parent.height
            color: Theme.accent
        }
    }
    Rectangle {
        x: root.fraction * track.width - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        radius: 8
        color: Theme.accent
        border.width: root.activeFocus ? 2 : 0
        border.color: Theme.foreground
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => {
            root.forceActiveFocus();
            root.setFromX(mouse.x);
        }
        onPositionChanged: mouse => {
            if (pressed)
                root.setFromX(mouse.x);
        }
        onReleased: root.released(root.value)
        onWheel: wheel => root.step(wheel.angleDelta.y > 0 ? 1 : -1)
    }
}
