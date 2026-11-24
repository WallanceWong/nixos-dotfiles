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
    property bool greet: false          // greet the new setup once it's in
    // NERV HQ → UNIT-01 is a launch (modules/Launch.qml draws it): the checklist
    // ticks off with command-room beeps, Misato's 発進！ (launch.wav starts on the
    // word, the catapult follows) and the switch itself while the screen is covered
    property bool launching: false
    readonly property var launch: ({ checks: [150, 380, 610, 840, 1070], go: 1250, swap: 1400, end: 4500 })
    Connections {
        target: Theme
        function onSetupChanged() { if (root.greet) { root.greet = false; Sounds.play("grant", 0.6); } }
    }

    function set(id) {
        if (id === Theme.setup || switching) return;
        switching = true;
        if (id === "unit01") {
            launching = true;
            launchClock.t = 0;
            launchClock.restart();
        } else {
            greet = true;
            run(id);
        }
    }
    function run(id) {
        proc.command = ["sh", "-c",
            "if command -v eva-switch >/dev/null; then exec eva-switch \"$0\"; fi; " +
            "mkdir -p \"$(dirname \"$1\")\" && printf '%s\\n' \"$0\" > \"$1\"", id, Theme.stateFile];
        proc.running = true;
    }
    // one 50 ms clock for the launch's sounds and the switch
    Timer {
        id: launchClock
        property int t: 0
        interval: 50
        repeat: true
        onTriggered: {
            const was = t;
            t += interval;
            const hit = ms => was < ms && t >= ms;
            const l = root.launch;
            if (l.checks.some(hit)) Sounds.play("toggle", 0.35, "magi");
            if (hit(l.go)) Sounds.play("launch", 0.7, "unit01");
            if (hit(l.swap)) root.run("unit01");
            if (t >= l.end) { stop(); root.launching = false; }
        }
    }
    function next() { set(Theme.magi ? "unit01" : "magi"); }

    Process {
        id: proc
        onExited: root.switching = false
    }
}
