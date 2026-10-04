pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Screen recording with gpu-screen-recorder (hardware encoding on the Intel GPU).
// Region: drag with slurp. Full screen: the whole display.
Singleton {
    id: root

    readonly property bool recording: rec.running
    property double startedAt: 0
    property string lastFile: ""
    readonly property string dir: Quickshell.env("HOME") + "/Videos/Recordings"

    function toggle(region) {
        if (rec.running) { rec.signal(2); return; }        // SIGINT: finish and save
        if (region) picker.running = true;
        else start(["-w", Hyprland.focusedMonitor?.name ?? "screen"]);
    }

    function start(target) {
        const stamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss");   // local time
        lastFile = dir + "/rec-" + stamp + ".mp4";
        rec.command = ["sh", "-c", 'mkdir -p "$1" && shift && exec gpu-screen-recorder "$@"', "sh", dir]
            .concat(target).concat(["-f", "60", "-a", "default_output", "-o", lastFile]);
        startedAt = Date.now();
        rec.running = true;
        Sounds.play("toggle");
    }

    Process {
        id: picker
        command: ["slurp", "-f", "%wx%h+%x+%y", "-b", "#071a2866", "-c", "#f0e3a8", "-w", "2"]
        stdout: StdioCollector {
            onStreamFinished: {
                const g = text.trim();
                if (g.length) root.start(["-w", "region", "-region", g]);
            }
        }
    }

    Process {
        id: rec
        onExited: (code, status) => {
            Quickshell.execDetached(["notify-send", "-a", "whisper", "-i", "media-record",
                                     code === 0 ? "Recording saved" : "Recording stopped",
                                     root.lastFile.replace(Quickshell.env("HOME"), "~")]);
        }
    }
}
