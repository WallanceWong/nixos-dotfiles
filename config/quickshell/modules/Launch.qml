import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// NERV HQ → UNIT-01 as a launch, over everything for 4.5 s (Setups.sequences.unit01 has
// the timings, and plays the sounds and the switch on the same beats):
//   0–0.33 s   blast doors shut over the desktop
//   0.33–1.25  the cage: Unit-01 (the real wallpaper) red-lit, the launch checklist
//   1.25 s     発進！ slams in with a flash, the eye flares; everything turns green
//              (the real switch happens behind it at 1.4 s)
//   2.1–3.3 s  the catapult: Unit-01 and the display rocket up, streaks, shaking
//   3.9–4.4 s  a green flash, the doors open onto the Unit-01 desktop
// Colours are fixed here: the theme flips halfway through.
Variants {
    model: Quickshell.screens.filter(s => !Quickshell.env("EVA_ONLY") || s.name === Quickshell.env("EVA_ONLY"))

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        readonly property color nerv: "#ff7a1a"
        readonly property color red: "#ff3b4a"
        readonly property color green: "#9be34a"
        readonly property color purple: "#9a7fe6"
        readonly property color dark: "#05060f"
        readonly property var l: Setups.sequences.unit01

        // ms since the launch began; EVA_LAUNCH_T freezes it (for screenshots)
        property real t: 0
        readonly property real frozen: Number(Quickshell.env("EVA_LAUNCH_T") || -1)
        NumberAnimation on t {
            id: clock
            running: false
            from: 0; to: win.l.end; duration: win.l.end
        }
        Connections {
            target: Setups
            function onSequenceChanged() { if (Setups.sequence === "unit01" && win.frozen < 0) clock.restart(); }
        }
        readonly property real now: frozen >= 0 ? frozen : t
        readonly property bool on: frozen >= 0 || clock.running || Setups.sequence === "unit01"

        function clamp(x) { return Math.max(0, Math.min(1, x)); }
        function span(a, b) { return clamp((now - a) / (b - a)); }
        readonly property bool go: now >= l.go                       // after 発進
        readonly property color tone: go ? green : nerv
        readonly property real rise: Math.pow(span(l.go + 850, l.go + 2050), 3)   // catapult (ease-in)
        readonly property real rush: span(l.go + 850, l.go + 1200) * (1 - span(3700, 4100))
        readonly property real shake: now > l.go && now < 3600 ? (1 - span(l.go, 3600)) * 14 : 0

        visible: on
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "eva-launch"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        // how far the blast doors are shut (they open onto the new desktop)
        readonly property real shut: span(l.shut[0], l.shut[1]) * (1 - Math.pow(span(l.open[0], l.open[1]), 2))

        // the desktop as it was, held still while the doors close over it
        ScreencopyView {
            anchors.fill: parent
            captureSource: win.on ? win.modelData : null
            live: false
            visible: win.now < win.l.shut[1] + 40
            Rectangle { anchors.fill: parent; color: win.red; opacity: 0.35 * win.span(0, win.l.shut[1]) }
        }
        BlastDoors {
            anchors.fill: parent
            shut: win.shut
            edge: win.go ? win.green : win.nerv
            label: "CAGE 07 · BLAST DOOR · " + (win.go ? "EVA-01 CLEARED" : "SEALED")
        }

        Item {
            id: stage
            anchors.fill: parent
            opacity: win.span(win.l.shut[1], win.l.shut[1] + 120) * (1 - win.span(win.l.open[0] - 150, win.l.open[0]))
            visible: opacity > 0
            clip: true

            // red alert wash that pulses during the countdown, green once launched
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.alpha(win.go ? win.green : win.red, 0.20) }
                    GradientStop { position: 0.5; color: "transparent" }
                    GradientStop { position: 1; color: Qt.alpha(win.go ? win.green : win.red, 0.20) }
                }
                opacity: win.go ? 0.7 : 0.55 + 0.45 * Math.abs(Math.sin(win.now / 180))
            }

            // the launch shaft: rails and rungs streaking down as the Eva goes up
            Item {
                id: shaft
                anchors.fill: parent
                opacity: 0.25 + 0.75 * win.rush
                readonly property real fall: win.now < win.l.go + 850 ? win.now * 0.05
                    : (win.l.go + 850) * 0.05 + (win.now - win.l.go - 850) * 3.2
                Repeater {
                    model: 14
                    Rectangle {
                        required property int index
                        width: parent.width * 0.62
                        x: parent.width * 0.19
                        height: 2
                        color: Qt.alpha(win.tone, 0.18)
                        y: ((index * 140 + shaft.fall) % (win.height + 140)) - 140
                    }
                }
                Repeater {
                    model: 90
                    Rectangle {
                        required property int index
                        readonly property real seed: (index * 7919 % 1000) / 1000
                        width: 1 + (index % 3)
                        height: (80 + seed * 380) * (0.3 + 1.8 * win.rush)
                        x: ((index * 0.618034 + 0.13) % 1) * win.width
                        y: ((seed * 3000 + shaft.fall * (0.8 + seed)) % (win.height + 600)) - 600
                        color: index % 5 === 0 ? win.purple : win.tone
                        opacity: (0.15 + 0.6 * seed) * (0.2 + 0.8 * win.rush)
                    }
                }
            }

            // everything that rides the catapult
            Item {
                id: rig
                width: parent.width
                height: parent.height
                x: win.shake * Math.sin(win.now / 23)
                y: -win.rise * win.height * 1.4 + win.shake * Math.cos(win.now / 17)

                // Unit-01 in the cage: the real wallpaper, red-lit and dark until
                // 発進 lights it and the eye flares; it rides the catapult up
                Item {
                    anchors.fill: parent
                    clip: true
                    Unit01Scene {
                        anchors.fill: parent
                        scale: 1.0 + 0.06 * win.span(win.l.shut[1], win.l.go)
                        animate: win.on
                        showDate: false
                        showCaption: false
                        eyeGlow: win.go ? "../assets/glow-green.png" : "../assets/glow-red.png"
                        eyeBoost: win.go ? 1.8 : 0.4 * win.span(win.l.shut[1], win.l.go)
                    }
                    Rectangle { anchors.fill: parent; color: win.dark; opacity: win.go ? 0.45 : 0.74 }
                    Rectangle { anchors.fill: parent; color: win.red; opacity: win.go ? 0 : 0.16 }
                }

                // hazard bands
                Hazard {
                    width: parent.width
                    height: 34
                    color: win.tone
                    gap: Qt.alpha(win.dark, 0.9)
                    stripe: 16
                    running: win.on
                    x: (1 - win.span(0, 260)) * -win.width
                }
                Hazard {
                    width: parent.width
                    y: parent.height - height
                    height: 34
                    color: win.tone
                    gap: Qt.alpha(win.dark, 0.9)
                    stripe: 16
                    running: win.on
                    x: (1 - win.span(0, 260)) * win.width
                }

                // the cage readout, top left
                Column {
                    x: 64; y: 70
                    spacing: 4
                    opacity: win.span(100, 300)
                    Text { text: "NERV · CENTRAL DOGMA · CAGE 07"; color: win.tone; font { family: Theme.hud; pixelSize: 18; letterSpacing: 4; weight: Font.DemiBold } }
                    Text { text: "PILOT · IKARI SHINJI · ENTRY PLUG INSERTED"; color: Qt.alpha("#e8e5e1", 0.6); font { family: Theme.hud; pixelSize: 15; letterSpacing: 3 } }
                }
                // sync ratio, top right
                Column {
                    anchors.right: parent.right; anchors.rightMargin: 64
                    y: 70
                    spacing: 0
                    opacity: win.span(150, 350)
                    Text { anchors.right: parent.right; text: "SYNC RATIO"; color: Qt.alpha("#e8e5e1", 0.6); font { family: Theme.hud; pixelSize: 15; letterSpacing: 3 } }
                    Text {
                        anchors.right: parent.right
                        text: (41.3 * win.span(100, win.l.go)).toFixed(1) + "%"
                        color: win.tone
                        font { family: Theme.hud; pixelSize: 54; weight: Font.Bold }
                    }
                }

                // title + checklist
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height * 0.13
                    spacing: 18
                    width: Math.min(parent.width - 128, 1180)

                    Item {
                        width: parent.width; height: 180
                        opacity: win.span(80, 280)
                        Text {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            text: "EVANGELION"
                            color: "#e8e5e1"
                            font { family: Theme.title; pixelSize: 100; weight: Font.Black }
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 6
                            text: "初号機"
                            color: win.go ? win.green : win.purple
                            font { family: Theme.title; pixelSize: 86; weight: Font.Black }
                        }
                    }
                    Rectangle { width: parent.width; height: 2; color: win.tone; opacity: 0.8 }
                    Text {
                        text: win.go ? "EVA-01 · LAUNCHED" : "EVA-01 · LAUNCH SEQUENCE"
                        color: win.tone
                        font { family: Theme.hud; pixelSize: 30; letterSpacing: 8; weight: Font.Bold }
                    }

                    Column {
                        width: parent.width
                        spacing: 8
                        Repeater {
                            model: [
                                ["冷却終了", "COOLING COMPLETE"],
                                ["第1ロックボルト解除", "PRIMARY LOCK BOLTS RELEASED"],
                                ["アンビリカルブリッジ移動", "UMBILICAL BRIDGE CLEAR"],
                                ["初号機 射出口へ", "EVA-01 TO LAUNCH PAD"],
                                ["進路クリア オールグリーン", "PATH CLEAR · ALL GREEN"]
                            ]
                            Item {
                                required property var modelData
                                required property int index
                                readonly property real at: win.l.checks[index]
                                readonly property real done: index < 4 ? win.l.checks[index + 1] : win.l.go
                                width: parent.width; height: 40
                                visible: win.now >= at
                                x: (1 - win.span(at, at + 120)) * -40
                                opacity: win.span(at, at + 120)
                                Text {
                                    text: "▶"
                                    color: win.tone
                                    font { family: Theme.hud; pixelSize: 22 }
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    x: 40
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData[0]
                                    color: "#e8e5e1"
                                    font { family: Theme.title; pixelSize: 30; weight: Font.Bold }
                                }
                                Text {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData[1] + "   " + (win.now >= done ? "OK" : "··")
                                    color: Qt.alpha(win.tone, 0.9)
                                    font { family: Theme.hud; pixelSize: 22; letterSpacing: 3; weight: Font.DemiBold }
                                }
                            }
                        }
                    }

                    // launch readiness bar
                    Item {
                        width: parent.width; height: 18
                        opacity: win.span(100, 300)
                        Rectangle { anchors.fill: parent; color: "transparent"; border.color: Qt.alpha(win.tone, 0.5); border.width: 1 }
                        Rectangle {
                            x: 3; y: 3; height: parent.height - 6
                            width: (parent.width - 6) * win.span(100, win.l.go)
                            color: win.tone
                        }
                    }
                }
            }

            // 発進！ — stays put while the rig flies off
            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: parent.height * 0.26
                visible: win.go
                text: "発進"
                color: win.green
                style: Text.Outline
                styleColor: Qt.alpha(win.dark, 0.8)
                font { family: Theme.title; pixelSize: 300; weight: Font.Black }
                scale: 2.4 - 1.4 * Math.pow(win.span(win.l.go, win.l.go + 160), 0.5)
                opacity: win.span(win.l.go, win.l.go + 90) * (1 - win.span(win.l.go + 1500, win.l.go + 2200))
                anchors.horizontalCenterOffset: win.shake * 0.6 * Math.sin(win.now / 19)
            }

            // flashes: white on 発進, green as the Eva clears the shaft
            Rectangle {
                anchors.fill: parent
                color: "white"
                opacity: win.go ? 0.85 * (1 - win.span(win.l.go, win.l.go + 260)) : 0
            }
            Rectangle {
                anchors.fill: parent
                color: win.green
                opacity: 0.55 * win.span(3600, 3800) * (1 - win.span(3800, 4300))
            }
        }
    }
}
