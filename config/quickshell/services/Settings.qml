pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Persistent toggles from the control centre, saved in Quickshell's state dir.
Singleton {
    id: root

    property alias sounds: adapter.sounds
    property alias dnd: adapter.dnd
    property alias launchCounts: adapter.launchCounts
    // living scene
    property alias parallax: adapter.parallax
    property alias musicReactive: adapter.musicReactive
    property alias moon: adapter.moon
    property alias skyClock: adapter.skyClock
    property alias meteors: adapter.meteors
    property alias fireflies: adapter.fireflies
    property alias ambience: adapter.ambience
    property alias ambienceVolume: adapter.ambienceVolume
    property alias corners: adapter.corners
    property alias batterySaver: adapter.batterySaver
    property alias autoGameMode: adapter.autoGameMode
    property alias autoPower: adapter.autoPower
    property alias screensaver: adapter.screensaver

    // not persisted: game mode always starts off
    property bool gameMode: false

    FileView {
        path: Quickshell.statePath("settings.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) writeAdapter(); }

        JsonAdapter {
            id: adapter
            property bool sounds: true
            property bool dnd: false
            property var launchCounts: ({})
            property bool parallax: true
            property bool musicReactive: true
            property bool moon: true
            property bool skyClock: true
            property bool meteors: true
            property bool fireflies: true
            property bool ambience: false
            property real ambienceVolume: 0.6
            property bool corners: true
            property bool batterySaver: true
            property bool autoGameMode: true
            property bool autoPower: true
            property bool screensaver: true
        }
    }

    function bumpLaunch(id) {
        const c = Object.assign({}, adapter.launchCounts);
        c[id] = (c[id] ?? 0) + 1;
        adapter.launchCounts = c;
    }
}
