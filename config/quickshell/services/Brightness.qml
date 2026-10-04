pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Screen brightness via brightnessctl (works without root through logind).
Singleton {
    id: root

    property real value: 1.0         // 0..1
    signal changedByUser()

    function refresh(announce) {
        reader.announce = announce ?? false;
        reader.running = true;
    }
    function set(v) {
        const pct = Math.round(Math.max(0.01, Math.min(1, v)) * 100);
        value = pct / 100;
        Quickshell.execDetached(["brightnessctl", "-q", "set", pct + "%"]);
    }

    Process {
        id: reader
        property bool announce: false
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                // intel_backlight,backlight,30720,100%,30720
                const f = text.trim().split(",");
                if (f.length >= 4) {
                    root.value = parseInt(f[3]) / 100;
                    if (reader.announce) root.changedByUser();
                }
            }
        }
    }

    Component.onCompleted: refresh(false)
}
