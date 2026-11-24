import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// UNIT-01 → NERV HQ as a scramble, over everything for ~7.5 s (Setups.sequences.magi
// has the timings, and plays the sounds and the switch on the same beats):
//   0–0.35 s   the desktop tears apart in red, the klaxon starts, blast doors slam
//   0.4–3.7 s  EMERGENCY on the doors: パターン青 as Shigeru reports it, then
//              ANGEL CONFIRMED on 間違いなく使徒です
//   3.7 s      総員第一種戦闘配置 slams in on the order
//   4.3–4.9 s  the MAGI come online one by one (承認); the real switch behind them
//   5.8 s      the NERV crest and 特務機関ネルフ slam in (第3新東京市、戦闘形態に移行します)
//   7.0–7.45 s the doors open onto the NERV HQ desktop
// Colours are fixed here: the theme flips halfway through.
Variants {
    model: Quickshell.screens.filter(s => !Quickshell.env("EVA_ONLY") || s.name === Quickshell.env("EVA_ONLY"))

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        readonly property color red: "#ff2a3d"
        readonly property color orange: "#ff7a1a"
        readonly property color amber: "#ffb020"
        readonly property color text: "#f2e8dc"
        readonly property color dark: "#0a0405"
        readonly property var s: Setups.sequences.magi
        readonly property var names: [["MELCHIOR", "1"], ["BALTHASAR", "2"], ["CASPER", "3"]]

        property real t: 0
        NumberAnimation on t {
            id: clock
            running: false
            from: 0; to: win.s.end; duration: win.s.end
        }
        Connections {
            target: Setups
            function onSequenceChanged() { if (Setups.sequence === "magi") clock.restart(); }
        }
        readonly property real now: t
        readonly property bool on: clock.running || Setups.sequence === "magi"

        function clamp(x) { return Math.max(0, Math.min(1, x)); }
        function span(a, b) { return clamp((now - a) / (b - a)); }
        readonly property bool magiUp: now >= s.magi[0] - 100
        readonly property bool slam: now >= s.nerv
        readonly property bool battle: now >= s.battle
        // the alarm blinks twice a second until the MAGI take over
        readonly property real blink: magiUp ? 0 : (Math.floor(now / 250) % 2 === 0 ? 1 : 0.35)
        readonly property real shake: slam && now < s.nerv + 600 ? (1 - span(s.nerv, s.nerv + 600)) * 16 : 0

        visible: on
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "eva-scramble"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        readonly property real shut: span(s.shut[0], s.shut[1]) * (1 - Math.pow(span(s.open[0], s.open[1]), 2))

        // the desktop as it was, tearing apart in red as the klaxon starts
        Item {
            id: glitch
            anchors.fill: parent
            visible: win.now < win.s.shut[1] + 40
            readonly property real amount: win.span(win.s.glitch[0] + 60, win.s.glitch[1])
            ScreencopyView {
                id: cap
                anchors.fill: parent
                captureSource: win.on ? win.modelData : null
                live: false
                visible: false
            }
            // horizontal slices, knocked sideways a little more every frame
            Repeater {
                model: 16
                Item {
                    required property int index
                    readonly property real h: win.height / 16
                    readonly property real jolt: Math.sin(index * 12.9898 + Math.floor(win.now / 40) * 78.233) * 43758.5453 % 1
                    y: index * h
                    width: win.width; height: h
                    clip: true
                    ShaderEffectSource {
                        sourceItem: cap
                        width: win.width; height: win.height
                        y: -parent.y
                        x: glitch.amount * parent.jolt * 180
                    }
                    // the red channel, pulled the other way
                    Rectangle {
                        width: win.width; height: parent.h
                        x: -glitch.amount * parent.jolt * 120
                        color: win.red
                        opacity: glitch.amount * 0.5
                    }
                }
            }
        }
        BlastDoors {
            anchors.fill: parent
            shut: win.shut
            edge: win.red
            plate: "#120708"
            label: "CENTRAL DOGMA · BLAST DOOR · " + (win.slam ? "NERV HQ" : "LOCKDOWN")
        }

        Item {
            id: stage
            anchors.fill: parent
            opacity: win.span(win.s.shut[1], win.s.shut[1] + 100) * (1 - win.span(win.s.open[0] - 150, win.s.open[0]))
            visible: opacity > 0
            clip: true
            x: win.shake * Math.sin(win.now / 21)
            y: win.shake * Math.cos(win.now / 15)

            Rectangle { anchors.fill: parent; color: win.dark; opacity: 0.8 }

            // the red pulse behind everything
            Rectangle {
                anchors.fill: parent
                color: win.red
                opacity: win.magiUp ? 0.06 : 0.10 + 0.22 * win.blink
            }
            // a scanline grid
            Repeater {
                model: Math.ceil(win.height / 6)
                Rectangle {
                    required property int index
                    y: index * 6; width: win.width; height: 1
                    color: Qt.alpha(win.red, 0.07)
                }
            }

            // EMERGENCY tickers, top and bottom, running opposite ways
            Repeater {
                model: 2
                Rectangle {
                    id: band
                    required property int index
                    width: win.width; height: 64
                    y: index === 0 ? 44 : win.height - 108
                    color: win.red
                    opacity: (win.magiUp ? 0.45 : 0.6 + 0.4 * win.blink) * win.span(80, 220)
                    clip: true
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        x: (band.index === 0 ? -1 : 1) * ((win.now * 0.35) % 560) - 560
                        spacing: 0
                        Repeater {
                            model: Math.ceil(win.width / 560) + 3
                            Text {
                                width: 560
                                text: "EMERGENCY  緊急"
                                color: win.dark
                                font { family: Theme.hud; pixelSize: 44; weight: Font.Black; letterSpacing: 6 }
                            }
                        }
                    }
                }
            }
            Hazard {
                width: parent.width; height: 14; y: 30
                color: win.amber; gap: win.dark; stripe: 10; running: win.on
                opacity: win.span(80, 220)
            }
            Hazard {
                width: parent.width; height: 14; y: win.height - 44
                color: win.amber; gap: win.dark; stripe: 10; running: win.on
                opacity: win.span(80, 220)
            }

            // ── the call to battle stations ──
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                y: win.height * 0.17
                spacing: 10
                opacity: win.span(win.s.shut[1], win.s.shut[1] + 100) * (1 - win.span(win.s.nerv - 150, win.s.nerv))
                // the title slams in twice: パターン青 as the report comes in, then the order
                scale: 1.3 - 0.3 * win.span(win.battle ? win.s.battle : win.s.shut[1], (win.battle ? win.s.battle : win.s.shut[1]) + 170)

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: win.battle ? "総員第一種戦闘配置" : "パターン青"
                    color: win.text
                    style: Text.Outline; styleColor: Qt.alpha(win.red, 0.6)
                    font { family: Theme.title; pixelSize: 104; weight: Font.Black }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: win.battle ? "ALL PERSONNEL · LEVEL-1 BATTLE STATIONS" : "WAVE PATTERN BLUE · 波長パターン青"
                    color: win.red
                    font { family: Theme.hud; pixelSize: 30; letterSpacing: 9; weight: Font.Bold }
                }
                // PATTERN BLUE, blinking until the MAGI take over
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: blue.implicitWidth + 60; height: 58
                    color: "transparent"
                    border.color: win.amber; border.width: 3
                    opacity: win.span(win.s.angel, win.s.angel + 70) * (win.magiUp ? 1 : win.blink)
                    Text {
                        id: blue
                        anchors.centerIn: parent
                        text: "間違いなく使徒です · ANGEL CONFIRMED"
                        color: win.amber
                        font { family: Theme.hud; pixelSize: 28; letterSpacing: 6; weight: Font.Bold }
                    }
                }
            }

            // ── the MAGI come online ──
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                y: win.height * 0.53
                spacing: 36
                opacity: 1 - win.span(win.s.nerv - 150, win.s.nerv)
                Repeater {
                    model: 3
                    Item {
                        id: unit
                        required property int index
                        readonly property real at: win.s.magi[index]
                        readonly property bool up: win.now >= at
                        width: Math.min(460, (win.width - 260) / 3); height: 210
                        visible: win.now >= at - 250
                        opacity: win.span(at - 250, at - 100)
                        Rectangle {
                            anchors.fill: parent
                            color: unit.up ? Qt.alpha(win.orange, 0.85) : Qt.alpha(win.red, 0.12)
                            border.color: unit.up ? win.amber : win.red
                            border.width: 2
                        }
                        // a white pop as it comes online
                        Rectangle { anchors.fill: parent; color: "white"; opacity: unit.up ? 0.8 * (1 - win.span(unit.at, unit.at + 200)) : 0 }
                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: win.names[unit.index][0] + "·" + win.names[unit.index][1]
                                color: unit.up ? win.dark : win.red
                                font { family: Theme.hud; pixelSize: 40; letterSpacing: 4; weight: Font.Black }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: unit.up ? "承認" : "起動中"
                                color: unit.up ? win.dark : Qt.alpha(win.red, 0.8)
                                font { family: Theme.title; pixelSize: 84; weight: Font.Black }
                            }
                        }
                    }
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: win.height * 0.53 + 236
                text: win.now >= win.s.magi[2] ? "MAGI SYSTEM · ALL ONLINE · 全会一致" : "MAGI SYSTEM · BOOT"
                color: win.amber
                visible: win.now >= win.s.magi[0] - 250
                opacity: 1 - win.span(win.s.nerv - 150, win.s.nerv)
                font { family: Theme.hud; pixelSize: 32; letterSpacing: 8; weight: Font.Bold }
            }

            // ── NERV ──
            Row {
                anchors.centerIn: parent
                spacing: 48
                visible: win.slam
                scale: 2.2 - 1.2 * Math.pow(win.span(win.s.nerv, win.s.nerv + 170), 0.5)
                opacity: win.span(win.s.nerv, win.s.nerv + 80)
                Item {
                    width: crest.width; height: 300
                    Image {
                        id: crest
                        source: "../assets/eva/nerv.svg"
                        height: 300
                        sourceSize.height: height
                        fillMode: Image.PreserveAspectFit
                        visible: false
                    }
                    MultiEffect { anchors.fill: parent; source: crest; colorization: 1; colorizationColor: win.red }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    Text { text: "特務機関"; color: win.text; font { family: Theme.title; pixelSize: 110; weight: Font.Black } }
                    Text { text: "NERV"; color: win.orange; font { family: Theme.title; pixelSize: 96; weight: Font.Black; letterSpacing: 24 } }
                    Text { text: "GEOFRONT · TOKYO-3 · CENTRAL DOGMA"; color: Qt.alpha(win.text, 0.7); font { family: Theme.hud; pixelSize: 24; letterSpacing: 6 } }
                }
            }

            // flashes: the red cut at the start, orange on the slam
            Rectangle { anchors.fill: parent; color: win.red; opacity: 0.7 * (1 - win.span(win.s.shut[1], win.s.shut[1] + 200)) }
            Rectangle { anchors.fill: parent; color: win.orange; opacity: win.slam ? 0.8 * (1 - win.span(win.s.nerv, win.s.nerv + 300)) : 0 }
        }
    }
}
