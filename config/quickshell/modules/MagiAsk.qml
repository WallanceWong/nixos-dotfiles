import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// Super + A (or "?" in the launcher): put a question to the MAGI. The three
// computers deliberate (審議中) while the local model thinks, then vote one by
// one — 承認 or 否決, each with its reason — and the resolution follows the
// majority. Esc closes.
PanelWindow {
    id: panel

    readonly property bool open: Panels.open === "magi"
    screen: Panels.screen
    visible: open || veil.opacity > 0
    WlrLayershell.namespace: "eva-magi"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    onOpenChanged: if (open) { field.text = Magi.busy ? Magi.question : ""; field.forceActiveFocus(); }

    readonly property real u: Math.min(width / 1920, height / 1200)

    // votes appear one after another once the answer is in
    property int revealed: 0
    Connections {
        target: Magi
        function onVotesChanged() { panel.revealed = 0; if (Magi.votes.length) reveal.restart(); }
        function onBusyChanged() { if (Magi.busy) { panel.revealed = 0; field.text = Magi.question; } }
    }
    Timer { id: reveal; interval: 650; repeat: true; onTriggered: { panel.revealed++; Sounds.play("tick", 0.5); if (panel.revealed >= 3) stop(); } }

    Rectangle {
        id: veil
        anchors.fill: parent
        color: Qt.alpha(Theme.crust, 0.82)
        opacity: panel.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.normal; easing.type: Theme.easing } }
        MouseArea { anchors.fill: parent; onClicked: Panels.close() }
    }

    Item {
        anchors.fill: parent
        opacity: veil.opacity
        scale: 0.97 + 0.03 * veil.opacity

        Column {
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 90 * panel.u }
            spacing: 6 * panel.u
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "MAGI SYSTEM"
                color: Theme.text
                font.family: Theme.hud
                font.pixelSize: 30 * panel.u
                font.weight: Font.Bold
                font.letterSpacing: 9 * panel.u
            }
            Caps {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "QUERY · LOCAL MODEL " + Magi.model.toUpperCase()
                color: Theme.overlay
                font.pixelSize: 12 * panel.u
            }
        }

        // ── the question ──
        Item {
            id: ask
            width: 900 * panel.u; height: 60 * panel.u
            anchors.horizontalCenter: parent.horizontalCenter
            y: 200 * panel.u
            HudFrame { anchors.fill: parent; fill: Qt.alpha(Theme.crust, 0.7); stroke: field.activeFocus ? Theme.accent : Theme.hairline; strokeWidth: 1.5; cut: 16 * panel.u; ticks: true }
            Text { x: 20 * panel.u; anchors.verticalCenter: parent.verticalCenter; text: "?"; color: Theme.accent; font.family: Theme.mono; font.pixelSize: 26 * panel.u; font.weight: Font.Bold }
            TextField {
                id: field
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 54 * panel.u; rightMargin: 20 * panel.u }
                background: null
                color: Theme.text
                placeholderText: "ASK THE MAGI A YES / NO QUESTION"
                placeholderTextColor: Theme.overlay
                font.family: Theme.hud
                font.pixelSize: 22 * panel.u
                font.weight: Font.DemiBold
                readOnly: Magi.busy
                Keys.onEscapePressed: Panels.close()
                onAccepted: Magi.ask(text)
            }
        }

        // ── the three computers ──
        Item {
            id: magi
            width: 1000 * panel.u; height: 600 * panel.u
            anchors.horizontalCenter: parent.horizontalCenter
            y: 300 * panel.u
            readonly property string phase: Magi.busy ? "thinking" : Magi.votes.length ? "done" : Magi.error.length ? "error" : "idle"

            Canvas {
                anchors.fill: parent
                property color c: magi.phase === "done" && panel.revealed >= 3 ? (Magi.approvals >= 2 ? Theme.signal : Theme.alert) : Theme.accent
                onCChanged: requestPaint()
                onWidthChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d"), u = panel.u, cw = 380 * u, ch = 250 * u, by = height - ch;
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
                y: 300 * panel.u
                text: "MAGI"
                color: Theme.text
                font.family: Theme.title
                font.weight: Font.Black
                font.pixelSize: 60 * panel.u
                font.letterSpacing: 10 * panel.u
            }

            // the pulse while deliberating
            property real t: 0
            NumberAnimation on t { running: Magi.busy && panel.open; from: 0; to: 1000; duration: 1000000; loops: Animation.Infinite }

            component Computer: Item {
                id: comp
                property int index: 0
                readonly property var v: Magi.votes[index]
                readonly property bool shown: magi.phase === "done" && panel.revealed > index
                readonly property string word: shown ? (v.yes ? "承認" : "否決") : magi.phase === "thinking" ? "審議中" : magi.phase === "error" ? "停止" : "待機"
                readonly property color tone: shown ? (v.yes ? Theme.signal : Theme.alert) : magi.phase === "thinking" ? Theme.caution : magi.phase === "error" ? Theme.alert : Theme.overlay
                width: 380 * panel.u; height: 250 * panel.u
                HudFrame {
                    anchors.fill: parent
                    fill: Qt.alpha(comp.tone, magi.phase === "thinking" ? 0.10 + 0.08 * Math.sin(magi.t * 9 + comp.index) : comp.shown ? 0.18 : 0.06)
                    stroke: comp.tone
                    strokeWidth: 2.5
                    cut: 26 * panel.u
                    cutTopRight: true
                    cutBottomLeft: true
                }
                Column {
                    anchors.centerIn: parent
                    width: parent.width - 40 * panel.u
                    spacing: 4 * panel.u
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: ["CASPER · 3", "BALTHASAR · 2", "MELCHIOR · 1"][comp.index]; color: Theme.text; font.family: Theme.hud; font.pixelSize: 22 * panel.u; font.weight: Font.Bold; font.letterSpacing: 4 * panel.u }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: comp.word; color: comp.tone; font.family: Theme.title; font.weight: Font.Black; font.pixelSize: 58 * panel.u }
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        text: comp.shown ? comp.v.reason : ["THE WOMAN · INTUITION", "THE MOTHER · CARE", "THE SCIENTIST · LOGIC"][comp.index]
                        color: comp.shown ? Theme.text : Theme.overlay
                        font.family: comp.shown ? Theme.font : Theme.hud
                        font.pixelSize: (comp.shown ? 15 : 12) * panel.u
                        font.letterSpacing: comp.shown ? 0 : 2 * panel.u
                    }
                }
            }
            Computer { index: 0; x: (magi.width - width) / 2; y: 0 }
            Computer { index: 1; x: 0; y: magi.height - height }
            Computer { index: 2; x: magi.width - width; y: magi.height - height }
        }

        // ── the resolution ──
        Column {
            anchors { horizontalCenter: parent.horizontalCenter; top: magi.bottom; topMargin: 30 * panel.u }
            spacing: 6 * panel.u
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: magi.phase === "thinking" ? "DELIBERATING… " + Math.floor((Date.now() - Magi.askedAt) / 1000 + magi.t * 0) + "S"
                    : magi.phase === "error" ? Magi.error
                    : magi.phase === "done" && panel.revealed >= 3 ? "RESOLUTION " + Magi.approvals + " / 3 · " + (Magi.approvals >= 2 ? "承認 · APPROVED" : "否決 · REJECTED")
                    : magi.phase === "done" ? "VOTING…" : "MAJORITY OF THREE DECIDES"
                color: magi.phase === "done" && panel.revealed >= 3 ? (Magi.approvals >= 2 ? Theme.signal : Theme.alert) : magi.phase === "error" ? Theme.alert : Theme.accent
                font.family: Theme.hud
                font.pixelSize: 20 * panel.u
                font.weight: Font.Bold
                font.letterSpacing: 4 * panel.u
            }
            Caps {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: magi.phase === "done" && panel.revealed >= 3
                text: "CODE 777 · " + (Magi.tookMs / 1000).toFixed(1) + " S · ENTER ASKS AGAIN · ESC CLOSES"
                color: Theme.overlay
                font.pixelSize: 12 * panel.u
            }
        }
    }
}
