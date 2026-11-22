pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Switching between the two setups. `eva-switch <id>` (installed by
// theme/eva.nix) flips ~/.config/eva/current, writes ~/.local/state/eva/setup
// (which Theme watches, so the shell repaints at once) and reloads Hyprland,
// kitty, GTK and the rest. Without the script (a test copy), only the state
// file is written.
Singleton {
    id: root

    readonly property var all: [
        { id: "unit01", name: "UNIT-01", subtitle: "SHINJI · CALM", icon: "shield", tone: "#9be34a" },
        { id: "magi", name: "NERV HQ", subtitle: "MAGI · FULL DRAMA", icon: "hub", tone: "#ff7a1a" }
    ]
    property bool switching: false
    property bool greet: false          // play the new setup's "grant" once it's in
    Connections {
        target: Theme
        function onSetupChanged() { if (root.greet) { root.greet = false; Sounds.play("grant", 0.6); } }
    }

    function set(id) {
        if (id === Theme.setup || switching) return;
        switching = true;
        greet = true;
        proc.command = ["sh", "-c",
            "if command -v eva-switch >/dev/null; then exec eva-switch \"$0\"; fi; " +
            "mkdir -p \"$(dirname \"$1\")\" && printf '%s\\n' \"$0\" > \"$1\"", id, Theme.stateFile];
        proc.running = true;
    }
    function next() { set(Theme.magi ? "unit01" : "magi"); }

    Process {
        id: proc
        onExited: root.switching = false
    }
}
