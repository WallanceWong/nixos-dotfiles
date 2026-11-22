pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Live machine readings for the HUDs — in Eva terms too: CPU = sync ratio,
// memory = LCL density, battery = internal / external power.
// Polls only while something on screen asks for it (`users` > 0).
Singleton {
    id: root

    property int users: 0
    property real cpu: 0               // 0..1
    property real mem: 0               // 0..1
    property string memText: ""
    property real temp: 0              // °C
    property var history: []           // recent cpu values, oldest first (60 samples)
    property var lastCpu: null

    // ── power ──
    readonly property var bat: UPower.displayDevice
    readonly property real battery: bat?.percentage ?? 0
    readonly property bool onBattery: bat?.state === UPowerDeviceState.Discharging
    readonly property bool charging: bat?.state === UPowerDeviceState.Charging || bat?.state === UPowerDeviceState.PendingCharge
    readonly property int timeLeft: onBattery ? (bat?.timeToEmpty ?? 0) : charging ? (bat?.timeToFull ?? 0) : 0   // seconds
    // "03:59:12" — the internal power countdown
    function clock(secs) {
        const s = Math.max(0, Math.floor(secs));
        return String(Math.floor(s / 3600)).padStart(2, "0") + ":" + String(Math.floor(s % 3600 / 60)).padStart(2, "0") + ":" + String(s % 60).padStart(2, "0");
    }
    // seconds left, counting down smoothly between UPower's updates
    property real countdown: timeLeft
    onTimeLeftChanged: countdown = timeLeft
    Timer { running: root.onBattery && root.users > 0; interval: 1000; repeat: true; onTriggered: root.countdown = Math.max(0, root.countdown - 1) }

    FileView { id: statFile; path: "/proc/stat" }
    FileView { id: memFile; path: "/proc/meminfo" }
    FileView { id: tempFile; path: "/sys/class/thermal/thermal_zone" + root.tempZone + "/temp" }

    function sample() {
        statFile.reload(); memFile.reload(); tempFile.reload();
        const f = statFile.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
        const idle = f[3] + f[4], total = f.reduce((a, b) => a + b, 0);
        if (lastCpu) cpu = Math.max(0, Math.min(1, 1 - (idle - lastCpu.idle) / Math.max(1, total - lastCpu.total)));
        lastCpu = { idle: idle, total: total };
        const m = {};
        for (const line of memFile.text().split("\n")) { const s = line.split(/:\s+/); if (s.length === 2) m[s[0]] = parseInt(s[1]); }
        if (m.MemTotal) {
            mem = 1 - m.MemAvailable / m.MemTotal;
            memText = ((m.MemTotal - m.MemAvailable) / 1048576).toFixed(1) + " / " + (m.MemTotal / 1048576).toFixed(1) + " GB";
        }
        temp = (parseInt(tempFile.text()) || 0) / 1000;
        const h = history.slice(-59);
        h.push(cpu);
        history = h;
    }

    Timer {
        running: root.users > 0
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.sample()
    }

    // the CPU package thermal zone, found once
    property int tempZone: 0
    Process {
        running: true
        command: ["sh", "-c", "for z in /sys/class/thermal/thermal_zone*; do [ \"$(cat $z/type)\" = x86_pkg_temp ] && basename $z | tr -dc 0-9 && exit; done; echo 0"]
        stdout: StdioCollector { onStreamFinished: root.tempZone = parseInt(text.trim()) || 0 }
    }
}
