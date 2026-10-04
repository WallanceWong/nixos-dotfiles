import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import qs.services
import qs.components

// Dashboard: drops from the clock. Time, calendar, music, how the laptop is doing.
PanelWindow {
    id: panel

    readonly property bool open: Panels.open === "dashboard"
    screen: Panels.screen
    visible: open || sheet.opacity > 0
    WlrLayershell.namespace: "whisper-dashboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true }
    margins { top: 54 }
    implicitWidth: 760
    implicitHeight: sheet.implicitHeight
    color: "transparent"

    HyprlandFocusGrab { active: panel.open; windows: [panel]; onCleared: Panels.close() }

    SystemClock { id: clock; precision: SystemClock.Seconds; enabled: panel.open }

    Rectangle {
        id: sheet
        width: parent.width
        implicitHeight: row.implicitHeight + 36
        radius: Theme.radius + 8
        color: Theme.glassStrong
        border.width: 1
        border.color: Qt.alpha(Theme.lamp, 0.22)
        opacity: panel.open ? 1 : 0
        transform: Translate { y: panel.open ? 0 : -24 }
        Behavior on opacity { NumberAnimation { duration: Theme.normal; easing.type: Theme.easing } }
        focus: panel.open
        Keys.onEscapePressed: Panels.close()

        RowLayout {
            id: row
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
            spacing: 18

            // ───────────── time + calendar ─────────────
            ColumnLayout {
                Layout.preferredWidth: 330
                Layout.maximumWidth: 330
                Layout.fillWidth: false
                Layout.alignment: Qt.AlignTop
                spacing: 2

                Row {
                    spacing: 8
                    Label { text: Qt.formatTime(clock.date, "HH:mm"); color: Theme.lamp; font.pixelSize: 64; font.weight: Font.Black }
                    Label { text: Qt.formatTime(clock.date, "ss"); color: Theme.overlay; font.pixelSize: 22; font.weight: Font.Bold; topPadding: 36 }
                }
                Label { text: Qt.formatDate(clock.date, "dddd, d MMMM yyyy"); color: Theme.text; font.pixelSize: 15 }
                Label {
                    readonly property var d: clock.date
                    function k(n) { const s = ["", "一", "二", "三", "四", "五", "六", "七", "八", "九"]; return n < 10 ? s[n] : n === 10 ? "十" : n < 20 ? "十" + s[n - 10] : s[Math.floor(n / 10)] + "十" + s[n % 10]; }
                    text: k(d.getMonth() + 1) + "月" + k(d.getDate()) + "日（" + ["日", "月", "火", "水", "木", "金", "土"][d.getDay()] + "）"
                    font.family: Theme.jp
                    font.pixelSize: 14
                    color: Theme.subtext
                    Layout.bottomMargin: 10
                }

                // calendar
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: cal.implicitHeight + 24
                    radius: Theme.radius
                    color: Theme.surface0
                    border.width: 1
                    border.color: Theme.hairline

                    ColumnLayout {
                        id: cal
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                        spacing: 6
                        property int offset: 0
                        Connections { target: panel; function onOpenChanged() { if (panel.open) cal.offset = 0; } }
                        readonly property date month: new Date(clock.date.getFullYear(), clock.date.getMonth() + offset, 1)

                        RowLayout {
                            Layout.fillWidth: true
                            IconButton { icon: "chevron_left"; implicitWidth: 30; implicitHeight: 30; onClicked: cal.offset-- }
                            Label { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: Qt.formatDate(cal.month, "MMMM yyyy"); font.weight: Font.ExtraBold; color: Theme.lamp }
                            IconButton { icon: "chevron_right"; implicitWidth: 30; implicitHeight: 30; onClicked: cal.offset++ }
                        }
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 7
                            rowSpacing: 2
                            columnSpacing: 2
                            Repeater {
                                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                                Label { required property string modelData; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: modelData; font.pixelSize: 11; color: Theme.teal }
                            }
                            Repeater {
                                model: 42
                                Rectangle {
                                    required property int index
                                    readonly property int lead: (cal.month.getDay() + 6) % 7
                                    readonly property date day: new Date(cal.month.getFullYear(), cal.month.getMonth(), index - lead + 1)
                                    readonly property bool inMonth: day.getMonth() === cal.month.getMonth()
                                    readonly property bool today: day.toDateString() === clock.date.toDateString()
                                    Layout.fillWidth: true
                                    implicitHeight: 30
                                    radius: 15
                                    color: today ? Theme.lamp : "transparent"
                                    Label {
                                        anchors.centerIn: parent
                                        text: day.getDate()
                                        font.pixelSize: 12
                                        font.weight: today ? Font.ExtraBold : Font.Medium
                                        color: today ? Theme.base : inMonth ? Theme.text : Theme.overlay
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ───────────── music + system ─────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 370
                Layout.alignment: Qt.AlignTop
                spacing: 12

                // now playing
                Rectangle {
                    id: music
                    readonly property var players: Mpris.players.values.filter(p => !p.dbusName.includes("playerctld"))
                    readonly property var player: players.find(p => p.isPlaying) ?? players[0]
                    Layout.fillWidth: true
                    implicitHeight: 152
                    radius: Theme.radius
                    color: Theme.surface0
                    border.width: 1
                    border.color: Theme.hairline
                    clip: true

                    // album art, softly blurred behind
                    Image {
                        anchors.fill: parent
                        source: music.player?.trackArtUrl ?? ""
                        fillMode: Image.PreserveAspectCrop
                        opacity: 0.18
                        visible: status === Image.Ready
                    }

                    Timer { running: panel.open && !!music.player?.isPlaying; interval: 1000; repeat: true; onTriggered: music.player.positionChanged() }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 14
                        visible: !!music.player

                        ClippingRectangle {
                            Layout.preferredWidth: 110
                            Layout.preferredHeight: 110
                            radius: 14
                            color: Theme.surface1
                            Image { anchors.fill: parent; source: music.player?.trackArtUrl ?? ""; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                            Icon { anchors.centerIn: parent; visible: !(music.player?.trackArtUrl ?? "").length; icon: "music_note"; size: 40; color: Theme.overlay }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Label { Layout.fillWidth: true; text: music.player?.trackTitle || "Unknown"; font.pixelSize: 15; font.weight: Font.ExtraBold; color: Theme.lamp }
                            Label { Layout.fillWidth: true; text: music.player?.trackArtist || music.player?.identity || ""; color: Theme.subtext }
                            Item { Layout.fillHeight: true }
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 4
                                radius: 2
                                color: Theme.surface2
                                visible: (music.player?.lengthSupported ?? false) && (music.player?.length ?? 0) > 0
                                Rectangle { height: parent.height; radius: 2; color: Theme.teal; width: parent.width * Math.min(1, (music.player?.position ?? 0) / Math.max(1, music.player?.length ?? 1)) }
                            }
                            RowLayout {
                                spacing: 4
                                IconButton { icon: "skip_previous"; enabled: music.player?.canGoPrevious ?? false; onClicked: music.player.previous() }
                                IconButton { icon: music.player?.isPlaying ? "pause" : "play_arrow"; iconSize: 26; active: true; onClicked: music.player.togglePlaying() }
                                IconButton { icon: "skip_next"; enabled: music.player?.canGoNext ?? false; onClicked: music.player.next() }
                            }
                        }
                    }
                    Column {
                        anchors.centerIn: parent
                        visible: !music.player
                        spacing: 6
                        Icon { anchors.horizontalCenter: parent.horizontalCenter; icon: "music_off"; size: 32; color: Theme.overlay }
                        Label { anchors.horizontalCenter: parent.horizontalCenter; text: "nothing playing"; color: Theme.overlay }
                    }
                }

                // system
                Rectangle {
                    id: sys
                    Layout.fillWidth: true
                    implicitHeight: stats.implicitHeight + 24
                    radius: Theme.radius
                    color: Theme.surface0
                    border.width: 1
                    border.color: Theme.hairline

                    property real cpu: 0
                    property var lastCpu: null
                    property real mem: 0
                    property string memText: ""
                    property real temp: 0

                    FileView { id: statFile; path: "/proc/stat" }
                    FileView { id: memFile; path: "/proc/meminfo" }
                    FileView { id: tempFile; path: "/sys/class/thermal/thermal_zone" + panel.tempZone + "/temp" }
                    Timer {
                        running: panel.open
                        interval: 2000
                        repeat: true
                        triggeredOnStart: true
                        onTriggered: {
                            statFile.reload(); memFile.reload(); tempFile.reload();
                            const f = statFile.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
                            const idle = f[3] + f[4], total = f.reduce((a, b) => a + b, 0);
                            const p = sys;
                            if (p.lastCpu) p.cpu = 1 - (idle - p.lastCpu.idle) / Math.max(1, total - p.lastCpu.total);
                            p.lastCpu = { idle: idle, total: total };
                            const m = {};
                            for (const line of memFile.text().split("\n")) { const s = line.split(/:\s+/); if (s.length === 2) m[s[0]] = parseInt(s[1]); }
                            p.mem = 1 - m.MemAvailable / m.MemTotal;
                            p.memText = ((m.MemTotal - m.MemAvailable) / 1048576).toFixed(1) + " / " + (m.MemTotal / 1048576).toFixed(1) + " GB";
                            p.temp = parseInt(tempFile.text()) / 1000;
                        }
                    }

                    GridLayout {
                        id: stats
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                        columns: 2
                        rowSpacing: 12
                        columnSpacing: 16

                        component Meter: ColumnLayout {
                            property string icon
                            property string name
                            property string valueText
                            property real value
                            property color accent: Theme.teal
                            Layout.fillWidth: true
                            spacing: 5
                            RowLayout {
                                Icon { icon: parent.parent.icon; size: 17; color: parent.parent.accent; fill: 1 }
                                Label { Layout.fillWidth: true; text: parent.parent.name; font.pixelSize: 12; color: Theme.subtext }
                                Label { text: parent.parent.valueText; font.pixelSize: 12; font.weight: Font.Bold }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 5
                                radius: 3
                                color: Theme.surface2
                                Rectangle { height: parent.height; radius: 3; color: parent.parent.accent; width: parent.width * Math.max(0, Math.min(1, parent.parent.value)); Behavior on width { NumberAnimation { duration: Theme.slow; easing.type: Theme.easing } } }
                            }
                        }

                        Meter { icon: "memory"; name: "CPU"; value: sys.cpu; valueText: Math.round(sys.cpu * 100) + "%"; accent: Theme.teal }
                        Meter { icon: "memory_alt"; name: "Memory"; value: sys.mem; valueText: sys.memText; accent: Theme.blue }
                        Meter { icon: "device_thermostat"; name: "Temperature"; value: (sys.temp - 30) / 70; valueText: Math.round(sys.temp) + "°C"; accent: sys.temp > 80 ? Theme.red : sys.temp > 65 ? Theme.mustard : Theme.green }
                        Meter {
                            readonly property var b: UPower.displayDevice
                            icon: "battery_horiz_075"
                            name: b?.state === UPowerDeviceState.Charging ? "Charging" : b?.state === UPowerDeviceState.Discharging ? "On battery" : "Plugged in"
                            value: b?.percentage ?? 0
                            valueText: {
                                const pct = Math.round((b?.percentage ?? 0) * 100) + "%";
                                const t = b?.state === UPowerDeviceState.Discharging ? b.timeToEmpty : b?.state === UPowerDeviceState.Charging ? b.timeToFull : 0;
                                return t > 0 ? pct + " · " + Math.floor(t / 3600) + "h " + Math.floor(t % 3600 / 60) + "m" : pct;
                            }
                            accent: Theme.lamp
                        }
                    }
                }
            }
        }
    }

    // pick the CPU package thermal zone once
    property int tempZone: 0
    Process {
        running: true
        command: ["sh", "-c", "for z in /sys/class/thermal/thermal_zone*; do [ \"$(cat $z/type)\" = x86_pkg_temp ] && basename $z | tr -dc 0-9 && exit; done; echo 0"]
        stdout: StdioCollector { onStreamFinished: panel.tempZone = parseInt(text.trim()) || 0 }
    }
}
