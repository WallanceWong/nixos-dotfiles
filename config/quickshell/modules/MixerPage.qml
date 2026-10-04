import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import qs.services
import qs.components

// Per-app volume: one slider for each app that is playing sound.
ColumnLayout {
    id: root
    spacing: 10

    Label {
        visible: Audio.streams.length === 0
        text: "no apps are playing sound"
        color: Theme.overlay
    }

    Repeater {
        model: Audio.streams
        ColumnLayout {
            id: app
            required property var modelData
            readonly property var node: modelData
            readonly property string name: node.properties["application.name"] ?? node.description ?? node.name
            Layout.fillWidth: true
            spacing: 4
            RowLayout {
                spacing: 8
                IconImage {
                    implicitSize: 18
                    source: Quickshell.iconPath(app.node.properties["application.icon-name"] ?? (DesktopEntries.heuristicLookup(app.name)?.icon ?? "audio-x-generic"), "audio-x-generic")
                }
                Label { Layout.fillWidth: true; text: app.name; font.pixelSize: 12 }
            }
            Slider {
                Layout.fillWidth: true
                icon: app.node.audio.muted ? "volume_off" : "volume_up"
                value: app.node.audio.volume
                dimmed: app.node.audio.muted
                accent: Theme.teal
                onMoved: v => { app.node.audio.muted = false; app.node.audio.volume = v; }
                onIconClicked: app.node.audio.muted = !app.node.audio.muted
            }
        }
    }
}
