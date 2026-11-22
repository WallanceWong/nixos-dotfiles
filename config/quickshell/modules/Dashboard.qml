import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.services
import qs.components

// Dashboard: drops from the clock. Segment clock and calendar; the music
// (Shinji's S-DAT tape player in UNIT-01, an audio link in NERV HQ); and the
// machine in Eva terms — sync ratio, LCL density, core temperature, power.
PanelWindow {
    id: panel

    readonly property bool open: Panels.open === "dashboard"
    screen: Panels.screen
    visible: open || sheet.opacity > 0
    WlrLayershell.namespace: "eva-dashboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true }
    margins { top: 54 }
    implicitWidth: 800
    implicitHeight: sheet.implicitHeight
    color: "transparent"

    HyprlandFocusGrab { active: panel.open; windows: [panel]; onCleared: Panels.close() }
    SystemClock { id: clock; precision: SystemClock.Seconds; enabled: panel.open }
    StatsUser { active: panel.open }

    component Section: Item {
        id: sec
        property string title: ""
        property string code: ""
        default property alias content: inner.data
        implicitHeight: inner.childrenRect.height + 44
        HudFrame { anchors.fill: parent; cut: 12; fill: Qt.alpha(Theme.surface0, 0.75); stroke: Theme.hairline }
        Rectangle { x: 14; y: 0; width: secTitle.implicitWidth + 10; height: 2; color: Theme.accent }
        Caps { id: secTitle; x: 18; y: 10; text: sec.title; color: Theme.accent; font.pixelSize: 12; font.weight: Font.Bold; font.letterSpacing: 2.5 }
        Caps { anchors { right: parent.right; rightMargin: 14; top: parent.top; topMargin: 10 } text: sec.code; color: Theme.overlay; font.pixelSize: 10 }
        Item { id: inner; x: 14; y: 32; width: sec.width - 28; height: childrenRect.height }
    }

    Item {
        id: sheet
        width: parent.width
        implicitHeight: row.implicitHeight + 36
        height: implicitHeight
        opacity: panel.open ? 1 : 0
        transform: Translate { y: panel.open ? 0 : -24 }
        Behavior on opacity { NumberAnimation { duration: Theme.normal; easing.type: Theme.easing } }
        focus: panel.open
        Keys.onEscapePressed: Panels.close()

        HudFrame {
            anchors.fill: parent
            fill: Theme.glassStrong
            stroke: Qt.alpha(Theme.accent, 0.45)
            cut: 18
            ticks: true
            cutTopRight: true
            cutBottomLeft: true
        }

        RowLayout {
            id: row
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
            spacing: 16

            // ───────────── time + calendar ─────────────
            ColumnLayout {
                Layout.preferredWidth: 330
                Layout.maximumWidth: 330
                Layout.alignment: Qt.AlignTop
                spacing: 6

                Row {
                    spacing: 10
                    SevenSeg { text: Qt.formatTime(clock.date, "HH:mm"); digitHeight: 58; color: Theme.accent }
                    SevenSeg { text: Qt.formatTime(clock.date, "ss"); digitHeight: 24; color: Theme.armour; anchors.bottom: parent.bottom }
                }
                Row {
                    spacing: 12
                    topPadding: 4
                    Text {
                        readonly property var d: clock.date
                        function k(n) { const s = ["〇", "一", "二", "三", "四", "五", "六", "七", "八", "九"]; return n < 10 ? s[n] : n < 20 ? "十" + (n > 10 ? s[n - 10] : "") : s[Math.floor(n / 10)] + "十" + (n % 10 ? s[n % 10] : ""); }
                        text: k(d.getMonth() + 1) + "月" + k(d.getDate()) + "日"
                        font.family: Theme.title
                        font.weight: Font.Black
                        font.pixelSize: 22
                        color: Theme.text
                    }
                    Caps {
                        anchors.baseline: parent.children[0].baseline
                        text: Qt.formatDate(clock.date, "dddd · yyyy")
                        font.pixelSize: 13
                        color: Theme.subtext
                    }
                }

                Section {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    title: Qt.formatDate(cal.month, "MMMM yyyy")
                    code: "CALENDAR"
                    ColumnLayout {
                        id: cal
                        width: parent.width
                        spacing: 4
                        property int offset: 0
                        Connections { target: panel; function onOpenChanged() { if (panel.open) cal.offset = 0; } }
                        readonly property date month: new Date(clock.date.getFullYear(), clock.date.getMonth() + offset, 1)

                        RowLayout {
                            Layout.fillWidth: true
                            IconButton { icon: "chevron_left"; implicitWidth: 28; implicitHeight: 28; onClicked: cal.offset-- }
                            Item { Layout.fillWidth: true }
                            IconButton { icon: "today"; implicitWidth: 28; implicitHeight: 28; visible: cal.offset !== 0; onClicked: cal.offset = 0 }
                            IconButton { icon: "chevron_right"; implicitWidth: 28; implicitHeight: 28; onClicked: cal.offset++ }
                        }
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 7
                            rowSpacing: 2
                            columnSpacing: 2
                            Repeater {
                                model: ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]
                                Caps { required property string modelData; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: modelData; font.pixelSize: 11; color: Theme.armour }
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
                                    implicitHeight: 28
                                    color: today ? Theme.accent : "transparent"
                                    border.width: today ? 0 : (inMonth ? 1 : 0)
                                    border.color: Qt.alpha(Theme.overlay, 0.18)
                                    Text {
                                        anchors.centerIn: parent
                                        text: String(day.getDate()).padStart(2, "0")
                                        font.family: Theme.mono
                                        font.pixelSize: 11
                                        font.weight: today ? Font.Bold : Font.Normal
                                        color: today ? Theme.crust : inMonth ? Theme.text : Qt.alpha(Theme.overlay, 0.7)
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
                Layout.alignment: Qt.AlignTop
                spacing: 12

                Section {
                    id: music
                    readonly property var players: Mpris.players.values.filter(p => !p.dbusName.includes("playerctld"))
                    readonly property var player: players.find(p => p.isPlaying) ?? players[0]
                    readonly property bool playing: !!player?.isPlaying
                    Layout.fillWidth: true
                    title: Theme.magi ? "AUDIO LINK" : "S-DAT"
                    code: music.player?.identity?.toUpperCase() ?? "NO DEVICE"

                    Timer { running: panel.open && music.playing; interval: 1000; repeat: true; onTriggered: music.player.positionChanged() }

                    Item {
                        width: parent.width
                        height: 120

                        // the tape (UNIT-01) or the cover art (NERV HQ)
                        Item {
                            id: deck
                            width: 150; height: 104
                            anchors.verticalCenter: parent.verticalCenter
                            Rectangle {
                                visible: !Theme.magi
                                anchors.fill: parent
                                color: Qt.alpha(Theme.crust, 0.6)
                                border.color: Theme.armour
                                border.width: 1.5
                                Caps { x: 10; y: 6; text: "SONY · DAT"; font.pixelSize: 9; color: Theme.subtext }
                                Rectangle { x: 18; y: 30; width: parent.width - 36; height: 40; color: "transparent"; border.color: Qt.alpha(Theme.armour, 0.5) }
                                Repeater {
                                    model: 2
                                    Item {
                                        required property int index
                                        x: index === 0 ? 30 : parent.width - 30 - 30
                                        y: 35
                                        width: 30; height: 30
                                        Rectangle { anchors.fill: parent; radius: 15; color: "transparent"; border.color: Theme.armour; border.width: 2 }
                                        Item {
                                            anchors.fill: parent
                                            RotationAnimation on rotation { running: music.playing && panel.open && !Theme.magi; from: 0; to: 360; duration: 2200; loops: Animation.Infinite }
                                            Repeater {
                                                model: 6
                                                Rectangle { required property int index; width: 2; height: 8; color: Theme.armour; x: 14; y: 3; transformOrigin: Item.Bottom; rotation: index * 60; antialiasing: true }
                                            }
                                        }
                                    }
                                }
                                Caps {
                                    anchors { left: parent.left; leftMargin: 10; bottom: parent.bottom; bottomMargin: 6 }
                                    text: "TRACK " + String(25 + (music.player?.trackNumber ?? 0) % 2).padStart(2, "0")
                                    font.pixelSize: 10
                                    color: Theme.accent
                                }
                            }
                            ClippingRectangle {
                                visible: Theme.magi
                                anchors.fill: parent
                                radius: 0
                                color: Theme.surface1
                                border.color: Theme.hairline
                                border.width: 1
                                Image { anchors.fill: parent; source: music.player?.trackArtUrl ?? ""; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                                Icon { anchors.centerIn: parent; visible: !(music.player?.trackArtUrl ?? "").length; icon: "graphic_eq"; size: 40; color: Theme.overlay }
                            }
                        }

                        ColumnLayout {
                            anchors { left: deck.right; leftMargin: 14; right: parent.right; top: parent.top; bottom: parent.bottom }
                            spacing: 2
                            visible: !!music.player
                            Label { Layout.fillWidth: true; text: music.player?.trackTitle || "UNKNOWN"; font.pixelSize: 16; font.weight: Font.Bold; color: Theme.text }
                            Label { Layout.fillWidth: true; text: music.player?.trackArtist || music.player?.identity || ""; color: Theme.subtext; font.pixelSize: 13 }
                            Item { Layout.fillHeight: true }
                            // position as segments
                            Row {
                                id: posBar
                                Layout.fillWidth: true
                                height: 6
                                spacing: 2
                                visible: (music.player?.lengthSupported ?? false) && (music.player?.length ?? 0) > 0
                                readonly property real f: Math.min(1, (music.player?.position ?? 0) / Math.max(1, music.player?.length ?? 1))
                                Repeater {
                                    model: 36
                                    Rectangle { required property int index; width: (posBar.width - 35 * 2) / 36; height: 6; color: (index + 0.5) / 36 <= posBar.f ? Theme.armour : Qt.alpha(Theme.overlay, 0.25) }
                                }
                            }
                            RowLayout {
                                spacing: 4
                                IconButton { icon: "skip_previous"; enabled: music.player?.canGoPrevious ?? false; onClicked: music.player.previous() }
                                IconButton { icon: music.playing ? "pause" : "play_arrow"; iconSize: 24; active: true; onClicked: music.player.togglePlaying() }
                                IconButton { icon: "skip_next"; enabled: music.player?.canGoNext ?? false; onClicked: music.player.next() }
                                Item { Layout.fillWidth: true }
                                Caps { text: music.playing ? "▶ PLAY" : "■ STOP"; color: music.playing ? Theme.signal : Theme.overlay; font.pixelSize: 11; font.weight: Font.Bold }
                            }
                        }
                        Caps {
                            anchors { left: deck.right; leftMargin: 14; verticalCenter: parent.verticalCenter }
                            visible: !music.player
                            text: Theme.magi ? "NO SIGNAL" : "NO TAPE"
                            color: Theme.overlay
                            font.pixelSize: 14
                        }
                    }
                }

                Section {
                    Layout.fillWidth: true
                    title: Theme.magi ? "MAGI DIAGNOSTICS" : "UNIT STATUS"
                    code: "EVA-01"
                    Column {
                        width: parent.width
                        spacing: 10
                        Repeater {
                            model: [
                                { name: "SYNC RATIO", sub: "CPU", value: Stats.cpu, text: (Stats.cpu * 100).toFixed(1) + "%" },
                                { name: "LCL DENSITY", sub: "MEMORY", value: Stats.mem, text: Stats.memText },
                                { name: "CORE TEMP", sub: "PACKAGE", value: Math.max(0, Math.min(1, (Stats.temp - 30) / 70)), text: Math.round(Stats.temp) + " °C" },
                                { name: Stats.onBattery ? "INTERNAL POWER" : "EXTERNAL POWER", sub: Stats.onBattery ? Stats.clock(Stats.countdown) + " LEFT" : Stats.charging ? "CHARGING · " + Stats.clock(Stats.timeLeft) : "UMBILICAL", value: Stats.battery, text: Math.round(Stats.battery * 100) + "%" }
                            ]
                            Column {
                                id: gauge
                                required property var modelData
                                required property int index
                                width: parent.width
                                spacing: 4
                                Item {
                                    width: parent.width; height: 16
                                    Row {
                                        spacing: 8
                                        Caps { text: gauge.modelData.name; color: Theme.text; font.pixelSize: 12; font.weight: Font.Bold }
                                        Caps { text: gauge.modelData.sub; color: Theme.overlay; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                                    }
                                    Text { anchors.right: parent.right; text: gauge.modelData.text; color: Theme.text; font.family: Theme.mono; font.pixelSize: 12 }
                                }
                                Row {
                                    spacing: 2
                                    Repeater {
                                        model: 40
                                        Rectangle {
                                            required property int index
                                            readonly property real f: (index + 0.5) / 40
                                            readonly property bool isPower: gauge.index === 3
                                            width: (gauge.width - 39 * 2) / 40
                                            height: 9
                                            color: f > gauge.modelData.value ? Qt.alpha(Theme.overlay, 0.25)
                                                 : isPower ? (Stats.onBattery && gauge.modelData.value <= 0.15 ? Theme.alert : Theme.signal)
                                                 : f > 0.85 ? Theme.alert : f > 0.65 ? Theme.caution : Theme.accent
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
