pragma Singleton
import QtQuick
import Quickshell

// The ThinkPad's own lights join in (Settings.leds): the red dot on the lid
// logo beats slowly on internal power and blinks fast on alerts (critical
// messages, critical battery); the mic-mute light shows a recording. The
// system helper `eva-led` (configuration.nix) does the writing, through sudo
// with no password for just those modes.
Singleton {
    id: root

    property bool alerting: false
    // a few seconds of emergency blinking
    function alert(ms) {
        alerting = true;
        calm.interval = ms ?? 6000;
        calm.restart();
    }
    Timer { id: calm; onTriggered: root.alerting = false }

    readonly property string mode: !Settings.leds ? "normal"
        : alerting ? "alert"
        : Stats.onBattery ? "battery" : "normal"
    property string applied: ""
    onModeChanged: Qt.callLater(apply)
    function apply() {
        if (mode === applied) return;
        applied = mode;
        run(mode);
    }
    function run(m) { Quickshell.execDetached(["sudo", "-n", "/run/current-system/sw/bin/eva-led", m]); }

    // the low-battery moment
    readonly property bool critical: Stats.onBattery && Stats.battery <= 0.15
    onCriticalChanged: if (critical) alert(8000)

    // recording: the mic light stays on
    readonly property bool recording: Settings.leds && Recorder.recording
    onRecordingChanged: run(recording ? "record-on" : "record-off")

    Component.onCompleted: Qt.callLater(apply)
}
