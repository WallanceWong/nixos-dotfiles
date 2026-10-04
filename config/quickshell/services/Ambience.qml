pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Night ambience (off by default): crickets and the far-off city, a quiet
// loop (assets/sounds/night.ogg, made for this rice) that plays only while you
// can see the night — an empty desktop or the lock screen — and nothing else
// is making sound. Fades in and out on its own PipeWire stream.
Singleton {
    id: root

    readonly property var others: Audio.streams.filter(n => n.properties["application.name"] !== "whisper-ambience")
    readonly property bool wanted: Settings.ambience && !Settings.gameMode && !Audio.muted
                                   && others.length === 0 && (Desktop.skyVisible || Locker.locked)
    readonly property bool playing: player.running && level > 0.01

    // debounce: a window flashing past shouldn't stop the crickets
    property bool active: false
    onWantedChanged: settle.restart()
    Timer { id: settle; interval: 1500; onTriggered: root.active = root.wanted }

    property real level: active ? Settings.ambienceVolume * 0.6 : 0
    Behavior on level { NumberAnimation { duration: 2500; easing.type: Easing.InOutSine } }

    readonly property var node: Audio.streams.find(n => n.properties["application.name"] === "whisper-ambience") ?? null
    PwObjectTracker { objects: root.node ? [root.node] : [] }
    onLevelChanged: apply()
    onNodeChanged: apply()
    function apply() {
        if (node?.audio) node.audio.volume = level;
        if (active && !player.running) player.running = true;
        if (!active && level < 0.005 && player.running) player.running = false;
    }
    onActiveChanged: apply()

    Process {
        id: player
        command: ["mpv", "--no-video", "--no-terminal", "--loop-file=inf", "--audio-client-name=whisper-ambience",
                  "--af=afade=t=in:d=2", Theme.assets + "/sounds/night.ogg"]
    }
}
