import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Mpris
import qs.services

// The Eva-01 lock screen — the boot login (always, in both setups) and the
// UNIT-01 setup's lock. Unit-01 in the dark with its eye lit green; an Eva
// title card (clock, date, 逃げちゃダメだ); the pilot sync-code entry.
// At boot an activation sequence types itself out first.
Item {
    id: root

    property var screen: null
    property bool live: true
    property bool awake: true
    property bool entered: false
    property bool boot: Locker.boot
    property int shakes: 0
    onShakesChanged: shake.restart()
    // let "SYNC RATIO 100%" and the eye flare register before the screen goes
    Component.onCompleted: Locker.unlockDelay = 750

    readonly property bool deny: Locker.message.length > 0

    // ── Unit-01, in the dark ──
    Unit01Scene {
        id: scene
        anchors.fill: parent
        animate: root.live
        showDate: false
        showCaption: false
        eyeGlow: root.deny ? "../assets/glow-red.png" : "../assets/glow-green.png"
        eyeBoost: Locker.granted ? 1 : Locker.busy ? 0.5 + 0.3 * Math.sin(scene.t * 10) : root.deny ? 0.6 : 0.15
        layer.enabled: true
        layer.effect: MultiEffect {
            saturation: -0.55
            brightness: root.boot ? -0.62 : -0.48
            colorization: 0.35
            colorizationColor: "#2a1650"
        }
    }
    // the eye, again, above the darkening: it is the only thing truly lit
    Image {
        readonly property point e: scene.eyeOnScreen
        width: 260 + (Locker.granted ? 260 : 0)
        height: width
        x: e.x - width / 2; y: e.y - height / 2
        source: root.deny ? "../assets/glow-red.png" : "../assets/glow-green.png"
        opacity: (Locker.granted ? 1 : 0.65) * (0.75 + 0.25 * Math.sin(scene.t * 1.3))
        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
    }
    // a black fall-off on the left for the title card
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.alpha("#000000", 0.92) }
            GradientStop { position: 0.45; color: Qt.alpha("#000000", 0.55) }
            GradientStop { position: 0.75; color: "transparent" }
        }
    }

    // ── boot: activation sequence ──
    Column {
        id: bootSeq
        visible: root.boot
        x: 64; y: 60
        spacing: 3
        property int shown: 0
        readonly property var lines: [
            "MAGI SYSTEM ............ ONLINE",
            "EVA-01 · TEST TYPE ..... ACTIVATION",
            "LCL ELECTROLYSIS ....... OK",
            "A10 NERVE CONNECTION ... STANDBY",
            "PILOT AUTHENTICATION REQUIRED"
        ]
        Timer { running: root.boot && bootSeq.shown < bootSeq.lines.length; interval: 160; repeat: true; onTriggered: bootSeq.shown++ }
        Repeater {
            model: bootSeq.shown
            Text {
                required property int index
                text: "> " + bootSeq.lines[index]
                color: index === bootSeq.lines.length - 1 ? Theme.accent : Qt.alpha(Theme.subtext, 0.8)
                font.family: Theme.mono
                font.pixelSize: 13
            }
        }
    }

    // ── the title card ──
    Item {
        id: card
        x: 96
        y: root.height * 0.2
        width: root.width * 0.5
        height: col.implicitHeight
        opacity: root.entered && !Locker.unlocking && (!root.boot || bootSeq.shown >= 3) ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Locker.unlocking ? 300 : 900; easing.type: Easing.OutCubic } }

        SystemClock { id: clock; precision: SystemClock.Seconds }
        function kanji(n) {
            const d = ["〇", "一", "二", "三", "四", "五", "六", "七", "八", "九"];
            if (n < 10) return d[n];
            if (n < 20) return "十" + (n > 10 ? d[n - 10] : "");
            return d[Math.floor(n / 10)] + "十" + (n % 10 ? d[n % 10] : "");
        }

        Column {
            id: col
            spacing: 0
            Text {
                text: root.boot ? "EVANGELION UNIT-01  ·  ACTIVATION" : "EVANGELION UNIT-01  ·  STANDBY"
                color: Theme.accent
                font.family: Theme.hud
                font.pixelSize: 16
                font.weight: Font.Bold
                font.letterSpacing: 5
                bottomPadding: 8
            }
            // the clock, title-card serif, squeezed
            Text {
                text: Qt.formatTime(clock.date, "HH:mm")
                color: "#ffffff"
                font.family: Theme.title
                font.weight: Font.Black
                font.pixelSize: Math.round(root.height * 0.2)
                lineHeight: 0.82
                transform: Scale { xScale: 0.86 }
            }
            Row {
                spacing: 18
                topPadding: 4
                Text {
                    text: card.kanji(clock.date.getMonth() + 1) + "月" + card.kanji(clock.date.getDate()) + "日"
                    color: "#ffffff"
                    font.family: Theme.title
                    font.weight: Font.Black
                    font.pixelSize: 34
                }
                Text {
                    anchors.baseline: parent.children[0].baseline
                    text: ["日", "月", "火", "水", "木", "金", "土"][clock.date.getDay()] + "曜日"
                    color: Qt.alpha("#ffffff", 0.7)
                    font.family: Theme.title
                    font.weight: Font.Bold
                    font.pixelSize: 22
                }
                Text {
                    anchors.baseline: parent.children[0].baseline
                    text: ":" + String(clock.date.getSeconds()).padStart(2, "0")
                    color: Theme.accent
                    font.family: Theme.mono
                    font.pixelSize: 18
                }
            }
            Item { width: 1; height: 44 }
            Text {
                text: "逃げちゃダメだ"
                color: "#ffffff"
                font.family: Theme.title
                font.weight: Font.Black
                font.pixelSize: 64
            }
            Text {
                text: "I MUSTN'T RUN AWAY."
                color: Qt.alpha("#ffffff", 0.75)
                font.family: Theme.title
                font.weight: Font.Black
                font.pixelSize: 22
                font.letterSpacing: 2
                topPadding: 6
            }
        }
    }

    // ── pilot authentication ──
    Item {
        id: entry
        x: 96
        y: root.height * 0.76
        width: 520
        height: 110
        opacity: root.entered && !Locker.unlocking && (root.awake || Locker.typed.length > 0) && (!root.boot || bootSeq.shown >= bootSeq.lines.length) ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
        transform: Translate { id: shakeT }
        SequentialAnimation {
            id: shake
            NumberAnimation { target: shakeT; property: "x"; to: -14; duration: 50 }
            NumberAnimation { target: shakeT; property: "x"; to: 12; duration: 70 }
            NumberAnimation { target: shakeT; property: "x"; to: -7; duration: 70 }
            NumberAnimation { target: shakeT; property: "x"; to: 3; duration: 70 }
            NumberAnimation { target: shakeT; property: "x"; to: 0; duration: 90 }
        }

        readonly property color tone: Locker.granted ? Theme.signal : root.deny ? Theme.alert : Locker.busy ? Theme.caution : Theme.accent

        Row {
            spacing: 14
            Text { text: "PILOT AUTHENTICATION"; color: entry.tone; font.family: Theme.hud; font.pixelSize: 14; font.weight: Font.Bold; font.letterSpacing: 3 }
            Text { text: "PILOT · " + (Quickshell.env("USER") ?? "").toUpperCase(); color: Theme.subtext; font.family: Theme.hud; font.pixelSize: 14; font.letterSpacing: 2 }
        }
        HudFrame {
            id: field
            y: 26
            width: parent.width
            height: 54
            fill: Qt.alpha("#000000", 0.55)
            stroke: Qt.alpha(entry.tone, 0.8)
            strokeWidth: 1.5
            cut: 14
            ticks: true
            tickColor: entry.tone

            // one lit block per typed character
            Row {
                anchors { left: parent.left; leftMargin: 22; verticalCenter: parent.verticalCenter }
                spacing: 6
                Repeater {
                    model: Math.min(Locker.typed.length, 24)
                    Rectangle {
                        width: 12; height: 22
                        color: entry.tone
                        scale: 0
                        Component.onCompleted: scale = 1
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                    }
                }
                Rectangle {
                    width: 12; height: 22
                    color: "transparent"
                    border.color: entry.tone
                    border.width: 1.5
                    visible: !Locker.busy && !Locker.granted
                    SequentialAnimation on opacity { loops: Animation.Infinite; NumberAnimation { to: 0; duration: 500 } NumberAnimation { to: 1; duration: 500 } }
                }
            }
            // checking: a sweep along the field
            Rectangle {
                visible: Locker.busy
                y: parent.height - 3
                height: 3
                width: parent.width * 0.25
                color: Theme.caution
                NumberAnimation on x { running: Locker.busy; loops: Animation.Infinite; from: 0; to: field.width * 0.75; duration: 700 }
            }
        }
        Text {
            y: 90
            text: Locker.granted ? "SYNC RATIO 100%  ·  承認  ·  WELCOME BACK"
                : Locker.busy ? "SYNCHRONIZING…"
                : root.deny ? Locker.message + "  ·  否決"
                : "ENTER SYNC CODE"
            color: entry.tone
            font.family: Theme.hud
            font.pixelSize: 14
            font.weight: Font.Bold
            font.letterSpacing: 2.5
        }
    }

    // ── bottom right: power, music, unread ──
    Column {
        anchors { right: parent.right; bottom: parent.bottom; rightMargin: 64; bottomMargin: 56 }
        spacing: 10
        opacity: root.awake && !Locker.unlocking ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 600 } }

        readonly property var players: Mpris.players.values.filter(p => !p.dbusName.includes("playerctld"))
        readonly property var player: players.find(p => p.isPlaying) ?? players[0]
        readonly property int fresh: Math.max(0, Notifs.unread - Locker.unreadAtLock)

        Text {
            anchors.right: parent.right
            visible: !!parent.player && (parent.player.trackTitle ?? "").length > 0
            text: (parent.player?.isPlaying ? "▶ " : "■ ") + (parent.player?.trackTitle ?? "") + ((parent.player?.trackArtist ?? "").length ? "  ·  " + parent.player.trackArtist : "")
            color: Theme.armour
            font.family: Theme.font
            font.pixelSize: 15
        }
        Text {
            anchors.right: parent.right
            visible: parent.fresh > 0
            text: parent.fresh + " NEW MESSAGE" + (parent.fresh > 1 ? "S" : "")
            color: Theme.accent
            font.family: Theme.hud
            font.pixelSize: 14
            font.weight: Font.Bold
            font.letterSpacing: 2
        }
        Row {
            anchors.right: parent.right
            spacing: 10
            Text {
                text: Stats.onBattery ? "INTERNAL" : "EXTERNAL"
                color: Stats.onBattery ? (Stats.battery <= 0.15 ? Theme.alert : Theme.caution) : Theme.signal
                font.family: Theme.hud
                font.pixelSize: 14
                font.weight: Font.Bold
                font.letterSpacing: 2
            }
            Text {
                text: Math.round(Stats.battery * 100) + "%"
                color: Theme.text
                font.family: Theme.mono
                font.pixelSize: 14
            }
        }
    }
}
