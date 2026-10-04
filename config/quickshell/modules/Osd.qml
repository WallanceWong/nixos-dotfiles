import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// Volume / microphone / brightness capsule at the bottom centre.
PanelWindow {
    id: root

    screen: Panels.screen
    WlrLayershell.namespace: "whisper-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    anchors { bottom: true }
    margins { bottom: 64 }
    implicitWidth: 320
    implicitHeight: 58
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

    Rectangle {
        id: capsule
        anchors.fill: parent
        radius: height / 2
        color: Theme.glassStrong
        border.width: 1
        border.color: Qt.alpha(Theme.teal, 0.45)
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.92
        Behavior on opacity { NumberAnimation { duration: Theme.normal; easing.type: Theme.easing } }
        Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutBack } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 20
            spacing: 12
            Icon { icon: root.icon; size: 22; fill: 1; color: root.dimmed ? Theme.overlay : Theme.lamp }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                RowLayout {
                    Layout.fillWidth: true
                    Label { Layout.fillWidth: true; text: root.label; font.pixelSize: 12; font.weight: Font.Bold }
                    Label { text: Math.round(root.value * 100) + "%"; font.pixelSize: 12; color: Theme.subtext }
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 6
                    radius: 3
                    color: Theme.surface1
                    Rectangle {
                        height: parent.height
                        radius: 3
                        width: parent.width * Math.min(1, root.value)
                        color: root.dimmed ? Theme.overlay : Theme.teal
                        Behavior on width { NumberAnimation { duration: Theme.fast; easing.type: Theme.easing } }
                    }
                }
            }
        }
    }
}
