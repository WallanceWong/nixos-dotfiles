pragma Singleton
import QtQuick
import QtQml
import Quickshell
import Quickshell.Services.Pipewire

// Night ambience (off by default): crickets and the far-off city, a quiet
// loop (assets/sounds/night.ogg, made for this rice) that plays whenever
// nothing else is making sound (not over fullscreen apps or in game mode).
// Fades in and out on its own PipeWire stream.
Singleton {
    id: root

    readonly property var others: Audio.streams.filter(n => n.properties["application.name"] !== "whisper-ambience")
    readonly property bool wanted: Settings.ambience && !Settings.gameMode && !Desktop.fullscreen
                                   && !Audio.muted && !othersAudible

    // an app with a stream open isn't necessarily making sound (a game in the
    // background, a paused video): listen to each one, and count it as playing
    // only if it was audible in the last few seconds
    property double lastHeard: 0
    readonly property bool othersAudible: heardRecently || unmeasurable
    property bool heardRecently: false
    // the level meter can't read mono streams (Roblox's is one): count those as
    // playing rather than let the crickets talk over them
    readonly property var measurable: others.filter(n => (n.audio?.channels?.length ?? 0) >= 2)
    readonly property bool unmeasurable: others.length > measurable.length
    Instantiator {
        model: Settings.ambience ? root.measurable : []
        delegate: PwNodePeakMonitor {
            required property var modelData
            node: modelData
            onPeakChanged: if (peak > 0.015) { root.lastHeard = Date.now(); root.heardRecently = true; }
        }
    }
    Timer {
        interval: 1000; repeat: true; running: root.heardRecently
        onTriggered: if (Date.now() - root.lastHeard > 4000) root.heardRecently = false
    }
    readonly property bool playing: node !== null && level > 0.01

    // debounce: a window flashing past shouldn't stop the crickets
    property bool active: false
    onWantedChanged: settle.restart()
    // a player left behind by an earlier shell (crash, reload) goes first
    Component.onCompleted: { Quickshell.execDetached(["pkill", "-f", "audio-client-name=whisper-ambience"]); settle.restart(); }
    Timer { id: settle; interval: 1500; onTriggered: root.active = root.wanted }

    property real level: active ? Settings.ambienceVolume : 0
    Behavior on level { NumberAnimation { duration: 2500; easing.type: Easing.InOutSine } }

    readonly property var node: Audio.streams.find(n => n.properties["application.name"] === "whisper-ambience") ?? null
    // the stream's volume can only be set once PipeWire has bound it
    Connections { target: root.node; function onReadyChanged() { root.apply(); } }
    onLevelChanged: apply()
    onNodeChanged: { if (!node && started && active) revive.restart(); apply(); }
    // if the player dies (or is killed), start it again a moment later
    Timer { id: revive; interval: 3000; onTriggered: if (!root.node && root.active) { root.started = false; root.apply(); } }
    onActiveChanged: apply()

    // mpv runs detached (only if its stream isn't there yet) and is stopped by name
    property bool started: false
    function apply() {
        if (node?.audio) node.audio.volume = level;
        if (active && !started) {
            started = true;
            if (!node)
                Quickshell.execDetached(["mpv", "--no-video", "--no-terminal", "--ao=pulse", "--loop-file=inf", "--audio-client-name=whisper-ambience",
                                         "--af=afade=t=in:d=2", Theme.assets + "/sounds/night.ogg"]);
        }
        if (!active && level < 0.005 && started) {
            started = false;
            Quickshell.execDetached(["pkill", "-f", "audio-client-name=whisper-ambience"]);
        }
    }
    Component.onDestruction: if (started) Quickshell.execDetached(["pkill", "-f", "audio-client-name=whisper-ambience"])
}
