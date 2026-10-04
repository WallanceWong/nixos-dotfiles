pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Which input method fcitx5 has active: English keyboard or Chinese pinyin.
// fcitx5-remote prints 1 (inactive = keyboard) or 2 (active = pinyin).
Singleton {
    id: root

    property bool available: false
    property bool chinese: false

    Timer {
        interval: 1200
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!probe.running) probe.running = true
    }

    Process {
        id: probe
        // via sh so a missing fcitx5 (before it is installed) stays quiet
        command: ["sh", "-c", "command -v fcitx5-remote >/dev/null && exec fcitx5-remote"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim();
                root.available = v === "1" || v === "2";
                root.chinese = v === "2";
            }
        }
        onExited: code => { if (code !== 0) root.available = false; }
    }

    function toggle() { Quickshell.execDetached(["fcitx5-remote", "-t"]); probe.running = true; }
}
