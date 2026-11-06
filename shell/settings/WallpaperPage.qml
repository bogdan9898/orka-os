// Wallpaper: the theme's own (its wallpaper, or its background color), or an
// image from ~/Pictures/Wallpapers (yours) or /usr/share/orka/wallpapers.
import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import qs

Page {
    id: page
    title: "Wallpaper"
    description: "Put your own images (JPEG, PNG, WebP) in ~/Pictures/Wallpapers; they show up here."

    readonly property string userDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    readonly property var dirs: [userDir, "/usr/share/orka/wallpapers"]
    readonly property var filters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.JPG", "*.JPEG", "*.PNG", "*.WEBP"]

    Flow {
        Layout.fillWidth: true
        spacing: 14

        // The theme's default.
        Rectangle {
            readonly property bool current: Settings.wallpaper === ""
            readonly property string themeImage: Theme.theme.wallpaper ? Theme.theme.dir + "/" + Theme.theme.wallpaper : ""
            width: 224
            height: 126
            color: Theme.background
            border.width: current ? 3 : 1
            border.color: current ? Theme.accent : Qt.alpha(Theme.foreground, 0.3)

            Image {
                anchors.fill: parent
                anchors.margins: parent.border.width
                visible: parent.themeImage !== ""
                source: parent.themeImage !== "" ? "file://" + parent.themeImage : ""
                sourceSize: Qt.size(448, 252)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
            Text {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: 10
                text: "Theme default" + (parent.current ? "  " + Theme.icons.check : "")
                color: Theme.foreground
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.bold: true
                style: Text.Outline
                styleColor: Theme.background
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Settings.set(".wallpaper", "")
            }
        }

        Repeater {
            model: page.dirs

            Repeater {
                id: dirRepeater
                required property string modelData
                model: FolderListModel {
                    folder: "file://" + dirRepeater.modelData
                    nameFilters: page.filters
                    showDirs: false
                    sortField: FolderListModel.Name
                }

                Rectangle {
                    id: tile
                    required property string filePath
                    required property string fileName
                    readonly property bool current: Settings.wallpaper === filePath
                    width: 224
                    height: 126
                    color: Theme.background
                    border.width: current ? 3 : 1
                    border.color: current ? Theme.accent : Qt.alpha(Theme.foreground, 0.3)

                    Image {
                        anchors.fill: parent
                        anchors.margins: parent.border.width
                        source: "file://" + tile.filePath
                        sourceSize: Qt.size(448, 252)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    Text {
                        visible: tile.current
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 8
                        text: Theme.icons.check
                        color: Theme.accent
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize + 6
                        style: Text.Outline
                        styleColor: Theme.background
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Settings.set(".wallpaper", tile.filePath)
                    }
                }
            }
        }
    }

    Choice {
        text: Theme.icons.folder + "  Open my wallpapers folder"
        onClicked: Quickshell.execDetached(["xdg-open", page.userDir])
    }
}
