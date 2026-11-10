// Fonts: the interface font (shell, GTK and Qt apps, other apps' sans-serif)
// and the monospace font (terminal, Neovim, code in apps), each with a size
// (fonts.interface / fonts.monospace, applied by orka-settings). Every font
// button is drawn in its own font. Without a search the lists show fonts with
// Latin letters (and fixed-width ones for monospace); a search looks through
// all installed fonts.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs

Page {
    id: page
    title: "Fonts"
    description: "Apps that are already open may keep their old font until you restart them. The terminal changes right away."

    property var families: []   // [{ family, latin, mono }] (orka-settings fonts)

    onVisibleChanged: {
        if (visible)
            list.running = true;
    }

    Process {
        id: list
        running: true
        command: ["orka-settings", "fonts"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    page.families = JSON.parse(text);
                } catch (e) {
                    page.families = [];
                }
            }
        }
    }

    component FontChooser: ColumnLayout {
        id: chooser
        property string kind            // "interface" or "monospace"
        property string heading
        property string icon
        property string current         // "" = default
        property string defaultName     // what "Default" means here
        property string defaultFamily   // for the preview
        property int size               // 0 = default
        property int defaultSize
        property int minSize
        property int maxSize
        property string sample
        property string search: ""

        readonly property var shown: {
            const q = search.trim().toLowerCase();
            const mono = kind === "monospace";
            const all = page.families;
            if (q === "")
                return all.filter(f => f.latin && (!mono || f.mono));
            return all.filter(f => f.family.toLowerCase().includes(q)).slice(0, 40);
        }

        Layout.fillWidth: true
        spacing: 12

        Label {
            heading: true
            text: chooser.icon + "  " + chooser.heading
        }

        // Preview in the current font and size.
        Text {
            Layout.fillWidth: true
            text: chooser.sample
            color: Theme.foreground
            font.family: chooser.current || chooser.defaultFamily
            font.pointSize: chooser.size || chooser.defaultSize
            elide: Text.ElideRight
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6
            Choice {
                text: "Default (" + chooser.defaultName + ")"
                selected: chooser.current === ""
                onClicked: Settings.set(".fonts." + chooser.kind + ".family", null)
            }
            Repeater {
                model: chooser.shown
                Choice {
                    required property var modelData
                    text: modelData.family
                    fontFamily: modelData.family
                    selected: chooser.current === modelData.family
                    onClicked: Settings.set(".fonts." + chooser.kind + ".family", modelData.family)
                }
            }
        }

        // Search all installed fonts.
        Rectangle {
            Layout.preferredWidth: 360
            implicitHeight: 32
            color: "transparent"
            border.width: 1
            border.color: searchInput.activeFocus ? Theme.accent : Qt.alpha(Theme.foreground, 0.3)
            TextInput {
                id: searchInput
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.foreground
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                clip: true
                onTextChanged: chooser.search = text
                Keys.onEscapePressed: event => {
                    if (text !== "") {
                        text = "";
                        event.accepted = true;
                    } else {
                        event.accepted = false;   // closes Settings
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: searchInput.text === ""
                    text: "Search all installed fonts"
                    color: Theme.foreground
                    opacity: 0.4
                    font: searchInput.font
                }
            }
        }
        Label {
            dim: true
            visible: chooser.search.trim() !== "" && chooser.shown.length === 0
            text: "No installed font matches."
        }

        RowLayout {
            spacing: 12
            Label {
                Layout.fillWidth: false
                text: "Size"
            }
            Slider {
                id: sizeSlider
                Layout.preferredWidth: 300
                from: chooser.minSize
                to: chooser.maxSize
                stepSize: 1
                value: chooser.size || chooser.defaultSize
                onReleased: v => Settings.set(".fonts." + chooser.kind + ".size", v)
            }
            Label {
                Layout.fillWidth: false
                text: sizeSlider.value + " pt" + (chooser.size === 0 ? " (default)" : "")
            }
            Choice {
                visible: chooser.size !== 0
                text: "Default size"
                onClicked: Settings.set(".fonts." + chooser.kind + ".size", null)
            }
        }
    }

    FontChooser {
        kind: "interface"
        heading: "Interface font"
        icon: Theme.icons.font
        current: Settings.interfaceFont
        defaultName: "JetBrainsMono Nerd Font here, Adwaita Sans in apps"
        defaultFamily: Theme.defaultFont
        size: Settings.interfaceFontSize
        defaultSize: 11
        minSize: 8
        maxSize: 14
        sample: "The bar, menus, notifications and apps. 0123456789"
    }

    FontChooser {
        kind: "monospace"
        heading: "Monospace font"
        icon: Theme.icons.keyboard
        current: Settings.monospaceFont
        defaultName: "JetBrainsMono Nerd Font in the terminal, Adwaita Mono in apps"
        defaultFamily: "JetBrainsMono Nerd Font"
        size: Settings.monospaceFontSize
        defaultSize: 9
        minSize: 6
        maxSize: 18
        sample: "The terminal and code: {} [] () => != 0O 1lI"
    }
}
