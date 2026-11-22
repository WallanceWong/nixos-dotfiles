pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Networking

// The MAGI log: what actually happened on this machine, newest first — power,
// Wi-Fi, Bluetooth, USB devices, messages, locks, setup switches, game mode,
// system rebuilds. The NERV HQ wallpaper's ticker and the dashboard read it.
Singleton {
    id: root

    property var entries: []            // [{ time, text, level }] newest first, 24 kept
    function add(text, level) {
        const e = entries.slice(0, 23);
        e.unshift({ time: Date.now(), text: text, level: level ?? "info" });
        entries = e;
    }
    function stamp(e) { return Qt.formatTime(new Date(e.time), "HH:mm"); }

    // only after start-up has settled, so the initial state isn't "news"
    property bool ready: false
    Timer { running: true; interval: 5000; onTriggered: { root.ready = true; root.add("MAGI SYSTEM ONLINE · " + Theme.name); } }

    // ── power ──
    readonly property bool onBattery: Stats.onBattery
    onOnBatteryChanged: if (ready) add(onBattery ? "UMBILICAL CABLE DISCONNECTED · INTERNAL POWER" : "UMBILICAL CABLE CONNECTED · EXTERNAL POWER", onBattery ? "warn" : "ok")
    readonly property bool lowPower: Stats.onBattery && Stats.battery <= 0.15
    onLowPowerChanged: if (ready && lowPower) add("INTERNAL POWER CRITICAL · " + Math.round(Stats.battery * 100) + "%", "alert")

    // ── network ──
    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
    readonly property string net: wifi?.networks?.values?.find(n => n.connected)?.name ?? ""
    onNetChanged: if (ready) add(net.length ? "DATA LINK ESTABLISHED · " + net.toUpperCase() : "DATA LINK LOST", net.length ? "ok" : "warn")

    // ── bluetooth ──
    readonly property var btNames: Bluetooth.devices.values.filter(d => d.connected).map(d => d.name)
    property var btBefore: []
    onBtNamesChanged: {
        if (ready) {
            for (const n of btNames) if (!btBefore.includes(n)) add("BLUETOOTH LINK · " + String(n).toUpperCase(), "ok");
            for (const n of btBefore) if (!btNames.includes(n)) add("BLUETOOTH LINK LOST · " + String(n).toUpperCase(), "info");
        }
        btBefore = btNames;
    }

    // ── USB: unknown hardware is how the Angels get in ──
    Process {
        id: usb
        running: true
        command: ["udevadm", "monitor", "--udev", "--property", "--subsystem-match=usb/usb_device"]
        property var block: ({})
        stdout: SplitParser {
            onRead: line => {
                const p = usb;
                if (line.trim() === "") {
                    const b = p.block;
                    if (b.ACTION === "add" || b.ACTION === "remove") {
                        const name = (b.ID_MODEL_FROM_DATABASE || b.ID_MODEL || b.ID_VENDOR_FROM_DATABASE || "UNKNOWN DEVICE").replace(/_/g, " ");
                        if (root.ready) root.add((b.ACTION === "add" ? "USB CONTACT · " : "USB DEVICE REMOVED · ") + name.toUpperCase(), b.ACTION === "add" ? "warn" : "info");
                    }
                    p.block = {};
                } else {
                    const i = line.indexOf("=");
                    if (i > 0) { const b = p.block; b[line.slice(0, i)] = line.slice(i + 1); p.block = b; }
                }
            }
        }
    }

    // ── messages ──
    readonly property int notes: Notifs.history.count
    property int notesBefore: 0
    onNotesChanged: {
        if (ready && notes > notesBefore && notes > 0) {
            const n = Notifs.history.get(0);
            add("TRANSMISSION · " + String(n.appName).toUpperCase() + " · " + String(n.summary).toUpperCase().slice(0, 48), "info");
        }
        notesBefore = notes;
    }

    // ── the session ──
    readonly property bool locked: Locker.locked
    onLockedChanged: if (ready) add(locked ? "TERMINAL SEALED · AUTHORIZATION REQUIRED" : "AUTHORIZATION ACCEPTED · WELCOME BACK", "info")
    readonly property string setup: Theme.setup
    onSetupChanged: if (ready) add("SYSTEM RECONFIGURED · " + Theme.name, "ok")
    readonly property bool gameMode: Settings.gameMode
    onGameModeChanged: if (ready) add(gameMode ? "GAME MODE ENGAGED · EFFECTS OFFLINE" : "GAME MODE DISENGAGED", "info")

    // ── system rebuilds: /run/current-system moving to a new generation ──
    property string generation: ""
    Process {
        id: genProbe
        command: ["readlink", "/run/current-system"]
        stdout: StdioCollector {
            onStreamFinished: {
                const g = text.trim();
                if (root.generation.length && g !== root.generation && root.ready) root.add("SYSTEM REBUILT · NEW GENERATION ACTIVE", "ok");
                root.generation = g;
            }
        }
    }
    Timer { running: true; interval: 60000; repeat: true; triggeredOnStart: true; onTriggered: genProbe.running = true }
}
