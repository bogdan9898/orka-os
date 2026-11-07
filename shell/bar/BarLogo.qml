// The OrkaOS logo at the left end of the bar: the badge (black disc, white
// lines), the same in light and dark themes. Click: launcher; right click:
// Settings.
import QtQuick
import qs

Item {
    id: root
    signal clicked
    signal rightClicked

    implicitWidth: 22
    implicitHeight: 22

    Image {
        anchors.fill: parent
        source: Theme.logoBadge
        sourceSize: Qt.size(64, 64)   // rendered sharp, then scaled down smoothly
        smooth: true
        mipmap: true
        fillMode: Image.PreserveAspectFit
    }
    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => mouse.button === Qt.RightButton ? root.rightClicked() : root.clicked()
    }
}
