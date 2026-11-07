// About: system information (orka-settings about), read each time it's shown.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs

Page {
    id: page
    title: "About"
    description: "This computer and OrkaOS."

    property var info: ({})
    readonly property var rows: [
        ["System", info.os], ["Computer name", info.host], ["Installed", info.installed],
        ["Processor", info.cpu], ["Graphics", (info.gpu || "").split(";").join("\n")],
        ["Memory", info.memory], ["Disk (/)", info.disk], ["Up for", info.uptime],
        ["Kernel", info.kernel], ["Hyprland", info.hyprland], ["Quickshell", info.quickshell]
    ]

    onVisibleChanged: {
        if (visible)
            about.running = true;
    }

    Process {
        id: about
        running: true
        command: ["orka-settings", "about"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    page.info = JSON.parse(text);
                } catch (e) {
                    page.info = {};
                }
            }
        }
    }

    RowLayout {
        spacing: 20
        Image {
            Layout.preferredWidth: 120
            Layout.preferredHeight: 120
            source: Theme.logoFull
            sourceSize: Qt.size(240, 240)
            smooth: true
            mipmap: true
        }
        ColumnLayout {
            spacing: 4
            Label {
                heading: true
                text: page.info.osName || "OrkaOS"
            }
            Label {
                dim: true
                text: page.info.osVersion ? "Version " + page.info.osVersion : ""
                visible: text !== ""
            }
        }
    }
    Repeater {
        model: page.rows.filter(r => r[1])
        RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 24
            Label {
                Layout.preferredWidth: 160
                Layout.fillWidth: false
                Layout.alignment: Qt.AlignTop
                dim: true
                text: parent.modelData[0]
            }
            Label {
                text: parent.modelData[1]
            }
        }
    }
}
