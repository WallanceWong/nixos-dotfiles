import QtQuick
import Quickshell
import qs.services

// The NERV HQ lock screen: the MAGI vote. Type the authorization code; on
// Enter the three computers deliberate (審議中) and then vote one after
// another — three 承認 and the doors open, 否決 and the room goes red.
Item {
    id: root

    property var screen: null
    property bool live: true
    property bool awake: true
    property bool entered: false
    property int shakes: 0
    onShakesChanged: { shake.restart(); denied.restart(); }

    Component.onCompleted: Locker.unlockDelay = 1500
    Component.onDestruction: Locker.unlockDelay = 320

    readonly property bool deny: Locker.message.length > 0
    // the vote: idle, deliberating, then revealed one by one
    property int revealed: 0
    readonly property string phase: Locker.granted ? "yes" : deny ? "no" : Locker.busy ? "thinking" : "idle"
    onPhaseChanged: { revealed = 0; if (phase === "yes" || phase === "no") reveal.restart(); }
    Timer { id: reveal; interval: 280; repeat: true; onTriggered: { root.revealed++; Sounds.play("tick", 0.5); if (root.revealed >= 3) stop(); } }

    MagiScene {
        id: scene
        anchors.fill: parent
        animate: root.live
        compact: true
        showMagi: false
        opacity: 0.55
    }

    // red room on a denial
    Rectangle {
        id: redRoom
        anchors.fill: parent
        color: Theme.alert
        opacity: 0
        SequentialAnimation {
            id: denied
            NumberAnimation { target: redRoom; property: "opacity"; to: 0.28; duration: 80 }
            NumberAnimation { target: redRoom; property: "opacity"; to: 0.06; duration: 260 }
            NumberAnimation { target: redRoom; property: "opacity"; to: 0.22; duration: 120 }
            NumberAnimation { target: redRoom; property: "opacity"; to: 0; duration: 700 }
        }
    }

    Item {
        id: ui
        anchors.fill: parent
        opacity: root.entered && !Locker.unlocking ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Locker.unlocking ? 300 : 500; easing.type: Easing.OutCubic } }
        readonly property real u: scene.u

        SystemClock { id: clock; precision: SystemClock.Seconds }

        // ── clock ──
        Column {
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 70 * ui.u }
            spacing: 10 * ui.u
            SevenSeg {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(clock.date, "HH:mm:ss")
                digitHeight: 74 * ui.u
                color: Theme.accent
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(clock.date, "dddd · dd MMMM yyyy").toUpperCase() + "  ·  ACCESS RESTRICTED"
                color: Theme.subtext
                font.family: Theme.hud
                font.pixelSize: 16 * ui.u
                font.weight: Font.DemiBold
                font.letterSpacing: 4 * ui.u
            }
        }

        // ── the MAGI ──
        Item {
            id: magi
            width: 880 * ui.u; height: 560 * ui.u
            anchors.horizontalCenter: parent.horizontalCenter
            y: 250 * ui.u

            Canvas {
                anchors.fill: parent
                property color c: root.phase === "no" ? Theme.alert : root.phase === "yes" ? Theme.signal : Theme.accent
                onCChanged: requestPaint()
                onWidthChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d"), u = ui.u, cw = 360 * u, ch = 220 * u, by = height - ch;
                    ctx.reset();
                    ctx.strokeStyle = Qt.alpha(c, 0.8);
                    ctx.lineWidth = 12 * u;
                    ctx.beginPath();
                    ctx.moveTo(width / 2 - 50 * u, ch); ctx.lineTo(cw / 2 + 30 * u, by);
                    ctx.moveTo(width / 2 + 50 * u, ch); ctx.lineTo(width - cw / 2 - 30 * u, by);
                    ctx.moveTo(cw, by + ch / 2); ctx.lineTo(width - cw, by + ch / 2);
                    ctx.stroke();
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 280 * ui.u
                text: "MAGI"
                color: Theme.text
                font.family: Theme.title
                font.weight: Font.Black
                font.pixelSize: 60 * ui.u
                font.letterSpacing: 10 * ui.u
            }

            component Computer: Item {
                id: comp
                property int index: 0
                property string name: ""
                property string side: ""
                readonly property bool shown: root.revealed > index
                readonly property string vote: root.phase === "thinking" ? "審議中"
                    : root.phase === "yes" ? (shown ? "承認" : "審議中")
                    : root.phase === "no" ? (shown ? "否決" : "審議中")
                    : "待機"
                readonly property color tone: vote === "承認" ? Theme.signal : vote === "否決" ? Theme.alert : vote === "審議中" ? Theme.caution : Theme.overlay
                width: 360 * ui.u; height: 220 * ui.u
                HudFrame {
                    anchors.fill: parent
                    fill: Qt.alpha(comp.tone, comp.vote === "審議中" ? 0.12 + 0.1 * Math.sin(scene.t * 9 + comp.index) : comp.vote === "待機" ? 0.06 : 0.2)
                    stroke: comp.tone
                    strokeWidth: 2.5
                    cut: 26 * ui.u
                    cutTopRight: true
                    cutBottomLeft: true
                }
                Column {
                    anchors.centerIn: parent
                    spacing: 2 * ui.u
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: comp.name; color: Theme.text; font.family: Theme.hud; font.pixelSize: 24 * ui.u; font.weight: Font.Bold; font.letterSpacing: 4 * ui.u }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: comp.side; color: Qt.alpha(comp.tone, 0.9); font.family: Theme.hud; font.pixelSize: 13 * ui.u; font.weight: Font.Bold; font.letterSpacing: 4 * ui.u }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: comp.vote; color: comp.tone; font.family: Theme.title; font.weight: Font.Black; font.pixelSize: 66 * ui.u }
                }
            }
            Computer { index: 0; name: "CASPER · 3"; side: "THE BOY"; x: (magi.width - width) / 2; y: 0 }
            Computer { index: 1; name: "BALTHASAR · 2"; side: "ME"; x: 0; y: magi.height - height }
            Computer { index: 2; name: "MELCHIOR · 1"; side: "THE BUILDER"; x: magi.width - width; y: magi.height - height }
        }

        // ── the authorization code ──
        Item {
            id: entry
            width: 620 * ui.u; height: 120 * ui.u
            anchors.horizontalCenter: parent.horizontalCenter
            y: 870 * ui.u
            opacity: root.awake || Locker.typed.length > 0 || root.phase !== "idle" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 400 } }
            transform: Translate { id: shakeT }
            SequentialAnimation {
                id: shake
                NumberAnimation { target: shakeT; property: "x"; to: -18; duration: 45 }
                NumberAnimation { target: shakeT; property: "x"; to: 16; duration: 60 }
                NumberAnimation { target: shakeT; property: "x"; to: -9; duration: 60 }
                NumberAnimation { target: shakeT; property: "x"; to: 4; duration: 60 }
                NumberAnimation { target: shakeT; property: "x"; to: 0; duration: 80 }
            }
            readonly property color tone: root.phase === "yes" ? Theme.signal : root.phase === "no" ? Theme.alert : root.phase === "thinking" ? Theme.caution : Theme.accent

            Item {
                width: parent.width; height: 20 * ui.u
                Text { anchors.left: parent.left; text: "AUTHORIZATION CODE"; color: entry.tone; font.family: Theme.hud; font.pixelSize: 15 * ui.u; font.weight: Font.Bold; font.letterSpacing: 3 * ui.u }
                Text { anchors.right: parent.right; text: "OPERATOR · " + (Quickshell.env("USER") ?? "").toUpperCase(); color: Theme.subtext; font.family: Theme.hud; font.pixelSize: 15 * ui.u; font.letterSpacing: 2 * ui.u }
            }
            HudFrame {
                y: 28 * ui.u
                width: parent.width; height: 58 * ui.u
                fill: Qt.alpha("#000000", 0.7)
                stroke: entry.tone
                strokeWidth: 2
                cut: 16 * ui.u
                ticks: true
                tickColor: entry.tone
                Hazard {
                    visible: root.phase === "no"
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 2 }
                    height: 5
                    color: Theme.alert
                    stripe: 7
                    running: true
                }
                Row {
                    anchors.centerIn: parent
                    spacing: 8 * ui.u
                    Repeater {
                        model: Math.min(Locker.typed.length, 24)
                        Text { text: "◆"; color: entry.tone; font.pixelSize: 18 * ui.u }
                    }
                    Text {
                        visible: Locker.typed.length === 0
                        text: root.phase === "thinking" ? "MAGI DELIBERATING…" : root.phase === "yes" ? "ACCESS GRANTED" : root.phase === "no" ? Locker.message : "ENTER CODE"
                        color: entry.tone
                        font.family: Theme.hud
                        font.pixelSize: 18 * ui.u
                        font.weight: Font.Bold
                        font.letterSpacing: 4 * ui.u
                    }
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 96 * ui.u
                text: root.phase === "yes" ? "RESOLUTION 3 / 3 · 承認 · GATE OPEN"
                    : root.phase === "no" ? "RESOLUTION REJECTED · 否決"
                    : "MAJORITY OF THREE REQUIRED"
                color: Qt.alpha(entry.tone, 0.85)
                font.family: Theme.hud
                font.pixelSize: 13 * ui.u
                font.letterSpacing: 3 * ui.u
            }
        }
    }
}
