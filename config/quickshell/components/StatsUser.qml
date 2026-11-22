import QtQuick
import qs.services

// Drop into anything that shows live Stats: polling runs while one is active.
QtObject {
    property bool active: true
    property bool counted: false
    function sync() {
        if (active && !counted) { Stats.users++; counted = true; }
        else if (!active && counted) { Stats.users--; counted = false; }
    }
    onActiveChanged: sync()
    Component.onCompleted: sync()
    Component.onDestruction: if (counted) Stats.users--
}
