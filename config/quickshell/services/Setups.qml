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
    // every switch plays a ~7 s sequence over the screen, and the switch itself
    // happens (`swap`) while it's covered:
    //   → UNIT-01 (modules/Launch.qml): the launch checklist with command-room
    //     beeps, Misato's 発進！ (launch.wav starts on the word), the catapult
    //   → NERV HQ (modules/Scramble.qml): the Pattern Blue klaxon (if Klaxon is
    //     on), the MAGI coming online one by one, NERV slamming in
    property string sequence: ""        // the setup being switched to while its sequence plays
    // both: blast doors shut over the desktop (`shut`), the sequence plays on
    // them, and they open onto the new desktop (`open`). Voices (v-*.wav) are
    // cut from the anime: the bridge calling the launch; Shigeru's pattern-blue
    // report, the battle-stations order and Tokyo-3 changing to battle mode.
    readonly property var sequences: ({
        unit01: { shut: [150, 330], open: [6750, 7200], checks: [450, 850, 1250, 1650, 2050], go: 4300, swap: 4450, end: 7350,
                  cues: [[300, "door", 0.7], [350, "v-junbi", 0.85, "unit01"],
                         [450, "toggle", 0.3, "magi"], [850, "toggle", 0.3, "magi"], [1250, "toggle", 0.3, "magi"],
                         [1650, "toggle", 0.3, "magi"], [2050, "toggle", 0.3, "magi"], [2000, "v-allgreen", 0.85, "unit01"],
                         [4300, "launch", 0.7, "unit01"], [6750, "door", 0.4]] },
        magi: { glitch: [0, 300], shut: [200, 340], angel: 1500, battle: 3700, magi: [4300, 4600, 4900], nerv: 5800, swap: 4400,
                open: [7000, 7450], end: 7600,
                cues: [[120, "alarm", 0.55, "magi"], [310, "door", 0.7], [400, "v-blue", 0.9, "magi"], [3700, "v-battle", 0.9, "magi"],
                       [4300, "grant", 0.35, "magi"], [4600, "grant", 0.35, "magi"], [4900, "grant", 0.35, "magi"],
                       [5800, "deny", 0.5, "magi"], [5900, "v-tokyo3", 0.85, "magi"], [7000, "door", 0.4]] }
    })

    function set(id) {
        if (id === Theme.setup || switching || !sequences[id]) return;
        switching = true;
        sequence = id;
        clock.t = 0;
        clock.restart();
    }
    function run(id) {
        proc.command = ["sh", "-c",
            "if command -v eva-switch >/dev/null; then exec eva-switch \"$0\"; fi; " +
            "mkdir -p \"$(dirname \"$1\")\" && printf '%s\\n' \"$0\" > \"$1\"", id, Theme.stateFile];
        proc.running = true;
    }
    // one 50 ms clock for the sequence's sounds and the switch
    Timer {
        id: clock
        property int t: 0
        interval: 50
        repeat: true
        onTriggered: {
            const was = t;
            t += interval;
            const hit = ms => was < ms && t >= ms;
            const s = root.sequences[root.sequence];
            for (const c of s.cues) if (hit(c[0])) Sounds.play(c[1], c[2], c[3]);
            if (hit(s.swap)) root.run(root.sequence);
            if (t >= s.end) { stop(); root.sequence = ""; }
        }
    }
    function next() { set(Theme.magi ? "unit01" : "magi"); }

    Process {
        id: proc
        onExited: root.switching = false
    }
}
