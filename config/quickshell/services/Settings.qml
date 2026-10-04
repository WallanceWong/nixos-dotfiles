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
        }
    }

    function bumpLaunch(id) {
        const c = Object.assign({}, adapter.launchCounts);
        c[id] = (c[id] ?? 0) + 1;
        adapter.launchCounts = c;
    }
}
