// A clickable glyph or label in the bar.
import QtQuick
import qs

Text {
    id: root
    signal clicked
    signal rightClicked
    signal scrolled(int steps)   // +1 per wheel notch up, -1 down

    color: Theme.foreground
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    verticalAlignment: Text.AlignVCenter

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4   // a little easier to hit than the glyph itself
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
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
