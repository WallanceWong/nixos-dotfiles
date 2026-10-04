pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Default speaker + microphone, kept bound so their volume/mute are live.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool ready: sink?.ready ?? false

    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property bool micMuted: source?.audio?.muted ?? false

    // application streams, for the per-app mixer
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream && n.audio && !n.isSink && n.properties["media.class"] === "Stream/Output/Audio")

    PwObjectTracker { objects: [root.sink, root.source].concat(root.streams) }

    readonly property string icon: muted || volume < 0.005 ? "volume_off"
                                 : volume < 0.34 ? "volume_mute"
                                 : volume < 0.67 ? "volume_down" : "volume_up"

    function setVolume(v) { if (sink?.audio) { sink.audio.muted = false; sink.audio.volume = Math.max(0, Math.min(1, v)); } }
    function toggleMute() { if (sink?.audio) sink.audio.muted = !sink.audio.muted; }
    function setMic(v) { if (source?.audio) { source.audio.muted = false; source.audio.volume = Math.max(0, Math.min(1, v)); } }
    function toggleMic() { if (source?.audio) source.audio.muted = !source.audio.muted; }
}
