// Night light: warmer colors (hyprsunset). Also SUPER + CTRL + N.
import QtQuick
import QtQuick.Layouts
import qs

Page {
    id: page
    title: "Night light"
    description: "Warmer screen colors for the evening. Also toggled with SUPER + CTRL + N; stays on after logging in again."

    // While dragging: the label follows; the light is set when you let go.
    property int temperature: Settings.nightlightTemperature

    RowLayout {
        spacing: 8
        Choice {
            text: Theme.icons.night + "  On"
            selected: Settings.nightlightOn
            onClicked: Settings.set(".nightlight.on", true)
        }
        Choice {
            text: "Off"
            selected: !Settings.nightlightOn
            onClicked: Settings.set(".nightlight.on", false)
        }
    }

    Label {
        heading: true
        text: "Color temperature: " + page.temperature + " K"
    }
    RowLayout {
        spacing: 12
        Label {
            Layout.fillWidth: false
            dim: true
            text: "warmer"
        }
        Slider {
            Layout.preferredWidth: 360
            from: 2500
            to: 6500
            stepSize: 100
            value: Settings.nightlightTemperature
            onMoved: v => page.temperature = v
            onReleased: v => Settings.set(".nightlight.temperature", v)
        }
        Label {
            Layout.fillWidth: false
            dim: true
            text: "cooler"
        }
    }
    Label {
        dim: true
        text: "6500 K is about neutral daylight; 4000 K is the default; 2500 K is very warm."
    }
}
