pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Small things the desktop does by itself:
//  • battery saver — below 20% on battery the night goes still (no animation,
//    no blur, power-saver profile) and comes back when you plug in
//  • boards — an Arduino / CH340 plugged in gets a note with its port, and a
//    button to open PictoBlox
//  • auto game mode — Feral GameMode's start/end hooks (a game asking for
//    gamemode, e.g. Sober) call `qs ipc call whisper gamestart|gameend`
Singleton {
    id: root

    // ── battery saver ──
    readonly property var bat: UPower.displayDevice
    readonly property bool onBattery: !!bat?.isLaptopBattery && bat?.state === UPowerDeviceState.Discharging
    readonly property real pct: bat?.percentage ?? 1
    property bool saving: false
    property int profileBefore: PowerProfile.Balanced

    readonly property bool shouldSave: Settings.batterySaver && onBattery && pct < (saving ? 0.25 : 0.2)
    onShouldSaveChanged: Qt.callLater(apply)
    Component.onCompleted: Qt.callLater(apply)

    function apply() {
        if (shouldSave === saving) return;
        saving = shouldSave;
        if (saving) {
            profileBefore = PowerProfiles.profile;
            PowerProfiles.profile = PowerProfile.PowerSaver;
            if (!Settings.gameMode)
                Quickshell.execDetached(["hyprctl", "--batch", "keyword animations:enabled 0; keyword decoration:blur:enabled 0; keyword decoration:shadow:enabled 0"]);
            Quickshell.execDetached(["notify-send", "-a", "whisper", "-i", "battery-caution", "battery saver", Math.round(pct * 100) + "% left — the night goes still until you plug in"]);
        } else {
            if (PowerProfiles.profile === PowerProfile.PowerSaver) PowerProfiles.profile = profileBefore;
            if (!Settings.gameMode) Quickshell.execDetached(["hyprctl", "reload"]);
        }
    }

    // ── auto game mode ──
    property bool autoGame: false
    function gameStarted() {
        if (!Settings.autoGameMode || Settings.gameMode) return;
        autoGame = true;
        Desktop.setGameMode(true);
    }
    function gameEnded() {
        if (!autoGame) return;
        autoGame = false;
        Desktop.setGameMode(false);
    }

    // ── boards on a serial port ──
    property string board: ""           // e.g. "Arduino Uno · ttyACM0", "" when none
    property var known: []

    function openBoardApp() { Quickshell.execDetached(["pictoblox"]); }

    // one line per port: "ttyUSB0|1a86|USB Serial"
    Process {
        id: scan
        command: ["sh", "-c", "for d in /dev/ttyUSB* /dev/ttyACM*; do [ -e \"$d\" ] || continue; " +
                  "p=$(udevadm info -q property -n \"$d\"); " +
                  "v=$(printf '%s\\n' \"$p\" | sed -n 's/^ID_VENDOR_ID=//p'); " +
                  "m=$(printf '%s\\n' \"$p\" | sed -n 's/^ID_MODEL_FROM_DATABASE=//p'); " +
                  "[ -n \"$m\" ] || m=$(printf '%s\\n' \"$p\" | sed -n 's/^ID_MODEL=//p' | tr _ ' '); " +
                  "echo \"${d#/dev/}|$v|$m\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const ports = text.trim().split("\n").filter(l => l.length).map(l => {
                    const [dev, vendor, model] = l.split("|");
                    return { dev: dev, name: root.nameFor(vendor, model) };
                });
                for (const p of ports)
                    if (!root.known.includes(p.dev) && root.started) root.announce(p);
                root.known = ports.map(p => p.dev);
                root.board = ports.length ? ports[0].name + " · " + ports[0].dev : "";
                root.started = true;
            }
        }
    }
    property bool started: false

    function nameFor(vendor, model) {
        switch (vendor) {
        case "2341": case "2a03": return model && !/^\s*$/.test(model) ? model.replace(/^Arduino\s*/, "Arduino ") : "Arduino";
        case "1a86": return "CH340 board";
        case "10c4": return "CP210x board";
        case "0403": return "FTDI board";
        case "303a": return "ESP32";
        default: return model || "serial device";
        }
    }

    function announce(p) {
        boardNote.command = ["notify-send", "-a", "whisper", "-i", "media-flash", "-A", "open=Open PictoBlox",
                             p.name + " plugged in", "on /dev/" + p.dev + " — ready to upload"];
        boardNote.running = true;
    }
    Process {
        id: boardNote
        stdout: StdioCollector { onStreamFinished: if (text.trim() === "open") root.openBoardApp() }
    }

    // udev tells us when tty devices come and go; rescan a moment after
    Process {
        running: true
        command: ["udevadm", "monitor", "--udev", "--subsystem-match=tty"]
        stdout: SplitParser { onRead: line => { if (/\b(add|remove)\b/.test(line)) rescan.restart(); } }
    }
    Timer { id: rescan; interval: 700; onTriggered: scan.running = true }
    Timer { running: true; interval: 1500; onTriggered: scan.running = true }
}
