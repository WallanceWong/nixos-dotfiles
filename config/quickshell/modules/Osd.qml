import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// Volume / microphone / brightness readout at the bottom centre, as a
// segmented sync-ratio gauge.
PanelWindow {
    id: root

    screen: Panels.screen
    WlrLayershell.namespace: "eva-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    anchors { bottom: true }
    margins { bottom: 64 }
    implicitWidth: 360
    implicitHeight: 62
    color: "transparent"
    visible: shown || capsule.opacity > 0
    mask: Region {}

    property bool shown: false
    property string icon: "volume_up"
    property string label: "Volume"
    property real value: 0
    property bool dimmed: false

    function show(icon, label, value, dimmed) {
        root.icon = icon; root.label = label; root.value = value; root.dimmed = dimmed;
        shown = true;
        hide.restart();
    }
    Timer { id: hide; interval: 1400; onTriggered: root.shown = false }

    // react to the real state, whatever changed it (keys, mixer, apps)
    property bool armed: false
    Timer { running: true; interval: 1500; onTriggered: root.armed = true }
    Connections {
        target: Audio
        function onVolumeChanged() { if (root.armed && Audio.ready) { root.show(Audio.icon, "Volume", Audio.volume, Audio.muted); Sounds.tick(); } }
        function onMutedChanged() { if (root.armed && Audio.ready) root.show(Audio.icon, Audio.muted ? "Muted" : "Volume", Audio.volume, Audio.muted); }
        function onMicMutedChanged() { if (root.armed) root.show(Audio.micMuted ? "mic_off" : "mic", Audio.micMuted ? "Microphone off" : "Microphone on", Audio.micVolume, Audio.micMuted); }
    }
    Connections {
        target: Brightness
        function onChangedByUser() { root.show(Brightness.value > 0.66 ? "brightness_high" : Brightness.value > 0.33 ? "brightness_medium" : "brightness_low", "Brightness", Brightness.value, false); }
    }

    Item {
        id: capsule
        anchors.fill: parent
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.94
        Behavior on opacity { NumberAnimation { duration: Theme.normal; easing.type: Theme.easing } }
        Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutBack } }
        readonly property color tone: root.dimmed ? Theme.overlay : Theme.accent

        HudFrame {
            anchors.fill: parent
            fill: Theme.glassStrong
            stroke: Qt.alpha(capsule.tone, 0.6)
            cut: 14
            ticks: true
            tickColor: capsule.tone
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 20
            spacing: 14
            Icon { icon: root.icon; size: 24; fill: 1; color: capsule.tone }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                RowLayout {
                    Layout.fillWidth: true
                    Caps { Layout.fillWidth: true; text: root.label; font.pixelSize: 12; font.weight: Font.Bold; color: Theme.text; font.letterSpacing: 2.5 }
                    Text { text: String(Math.round(root.value * 100)).padStart(3, " ") + "%"; font.family: Theme.mono; font.pixelSize: 13; font.weight: Font.Bold; color: capsule.tone }
                }
                Row {
                    id: cells
                    Layout.fillWidth: true
                    height: 10
                    spacing: 2
                    Repeater {
                        model: 30
                        Rectangle {
                            required property int index
                            width: (cells.width - 29 * 2) / 30
                            height: cells.height
                            color: (index + 0.5) / 30 <= root.value ? (index >= 27 && !root.dimmed ? Theme.caution : capsule.tone) : Qt.alpha(Theme.overlay, 0.25)
                        }
                    }
                }
            }
        }
    }
}
