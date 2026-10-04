pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Which overlay is open. Only one at a time; opening one closes the others.
Singleton {
    id: root

    // overlays open on the focused monitor (WHISPER_SCREEN pins them, for testing)
    readonly property var screen: Quickshell.screens.find(s => s.name === (Quickshell.env("WHISPER_SCREEN") || Hyprland.focusedMonitor?.name)) ?? Quickshell.screens[0]

    property string open: ""          // "", "launcher", "control", "dashboard", "overview", "power"
    property string launcherMode: "apps"   // apps | clipboard | emoji | windows

    function toggle(name) { open = (open === name) ? "" : name; }
    function show(name) { open = name; }
    function close() { open = ""; }

    function launcher(mode) {
        if (open === "launcher" && launcherMode === mode) { open = ""; return; }
        launcherMode = mode;
        open = "launcher";
    }
}
