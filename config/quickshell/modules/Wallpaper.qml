import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services

// The living night: the painting, with its own stars twinkling, the city
// shimmering, the streetlamps breathing, fireflies, the occasional shooting
// star and the date written down the sky. Animates only while visible.
Variants {
    // WHISPER_ONLY limits the shell to one screen (used for testing)
    model: Quickshell.screens.filter(s => !Quickshell.env("WHISPER_ONLY") || s.name === Quickshell.env("WHISPER_ONLY"))

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "whisper-wallpaper"
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: Theme.crust

        readonly property bool animate: Desktop.skyVisible

        FileView {
            id: sceneFile
            path: Theme.dots + "/theme/scene.json"
            blockLoading: true
        }
        readonly property var scene: {
            try { return JSON.parse(sceneFile.text()); } catch (e) { return ({ image: [6400, 3600], stars: [], city: [], lamps: [], windows: [], fireflies: [0, 0, 1, 1], sky: [0, 0, 1, 1] }); }
        }

        Item {
            id: sky
            anchors.fill: parent

            // painting -> screen mapping (same as "cover")
            readonly property real s: Math.max(width / win.scene.image[0], height / win.scene.image[1])
            readonly property real ox: (width - win.scene.image[0] * s) / 2
            readonly property real oy: (height - win.scene.image[1] * s) / 2
            function mx(x) { return ox + x * s; }
            function my(y) { return oy + y * s; }

            Image {
                anchors.fill: parent
                source: "file://" + Theme.dots + "/wallpapers/wall.jpg"
                fillMode: Image.PreserveAspectCrop
                sourceSize.height: parent.height
                asynchronous: false
                cache: false
                smooth: true
            }

            // One shared clock drives every twinkle at 15 frames a second.
            // The motion is slow, so this looks the same as 60 fps but makes the
            // compositor redraw a quarter as often (much kinder to the battery).
            property real t: 0
            Timer {
                running: win.animate
                interval: 66
                repeat: true
                onTriggered: sky.t += 0.066
            }
            // a gentle 0..1 wave for each light, with its own speed and phase
            function wave(speed, phase) { return 0.5 + 0.5 * Math.sin(sky.t * speed + phase); }

            // ── lit windows: a slow warm breath ──
            Repeater {
                model: win.scene.windows
                Image {
                    required property var modelData
                    readonly property real speed: 0.5 + Math.random() * 0.4
                    readonly property real phase: Math.random() * 6.28
                    width: modelData[2] * sky.s * 2.2
                    height: modelData[3] * sky.s * 2.2
                    x: sky.mx(modelData[0]) - width / 2
                    y: sky.my(modelData[1]) - height / 2
                    source: "../assets/glow-warm.png"
                    opacity: 0.16 + 0.16 * sky.wave(speed, phase)
                }
            }

            // ── city lights: quick, small shimmer in their own colours ──
            Repeater {
                model: win.scene.city
                Image {
                    required property var modelData
                    readonly property real base: 0.25 + modelData[2] * 0.45
                    readonly property real speed: 2.2 + Math.random() * 3.5
                    readonly property real phase: Math.random() * 6.28
                    width: 9 + modelData[2] * 6
                    height: width
                    x: sky.mx(modelData[0]) - width / 2
                    y: sky.my(modelData[1]) - height / 2
                    source: "../assets/glow-" + modelData[3] + ".png"
                    opacity: base * (0.35 + 0.65 * sky.wave(speed, phase))
                }
            }

            // ── stars: the painting's own, twinkling slowly ──
            Repeater {
                model: win.scene.stars
                Image {
                    required property var modelData
                    readonly property bool faint: modelData[2] <= 0.18
                    readonly property real base: faint ? 0.32 : 0.45 + modelData[2] * 0.5
                    readonly property real speed: 0.7 + Math.random() * 1.6
                    readonly property real phase: Math.random() * 6.28
                    width: faint ? 9 : 14 + modelData[2] * 10
                    height: width
                    x: sky.mx(modelData[0]) - width / 2
                    y: sky.my(modelData[1]) - height / 2
                    source: "../assets/glow-white.png"
                    // sharpen the wave so stars rest bright and dip briefly
                    opacity: base * (faint ? 0.15 + 0.85 * sky.wave(speed, phase) : 0.3 + 0.7 * Math.pow(sky.wave(speed, phase), 0.6))
                }
            }

            // ── streetlamps: a slow breath and, rarely, a flicker ──
            Repeater {
                model: win.scene.lamps
                Image {
                    id: halo
                    required property var modelData
                    required property int index
                    readonly property real base: index === 0 ? 0.42 : 0.34
                    property real dip: 0          // flicker pulls the glow down briefly
                    width: modelData[2] * sky.s * 2.6
                    height: width
                    x: sky.mx(modelData[0]) - width / 2
                    y: sky.my(modelData[1]) - height / 2
                    source: "../assets/halo.png"
                    opacity: Math.max(0.05, base - 0.04 + 0.16 * sky.wave(0.6, index * 2.1) - dip)
                    SequentialAnimation {
                        id: flicker
                        NumberAnimation { target: halo; property: "dip"; to: 0.38; duration: 60 }
                        NumberAnimation { target: halo; property: "dip"; to: 0; duration: 90 }
                        PauseAnimation { duration: 120 }
                        NumberAnimation { target: halo; property: "dip"; to: 0.3; duration: 50 }
                        NumberAnimation { target: halo; property: "dip"; to: 0; duration: 260 }
                    }
                    Timer {
                        running: win.animate && halo.index === 0
                        repeat: true
                        interval: 28000 + Math.random() * 50000
                        onTriggered: { interval = 28000 + Math.random() * 50000; flicker.start(); }
                    }
                }
            }

            // ── fireflies in the bushes: slow wandering loops ──
            Repeater {
                model: 7
                Image {
                    readonly property var box: win.scene.fireflies
                    readonly property real cx: box[0] + Math.random() * (box[2] - box[0])
                    readonly property real cy: box[1] + Math.random() * (box[3] - box[1])
                    readonly property real rx: (box[2] - box[0]) * (0.08 + Math.random() * 0.12)
                    readonly property real ry: (box[3] - box[1]) * (0.06 + Math.random() * 0.1)
                    readonly property real speed: 0.12 + Math.random() * 0.15
                    readonly property real phase: Math.random() * 6.28
                    readonly property real blink: 0.5 + Math.random() * 0.6
                    width: 13
                    height: 13
                    x: sky.mx(cx + rx * Math.sin(sky.t * speed + phase)) - 6
                    y: sky.my(cy + ry * Math.sin(sky.t * speed * 1.7 + phase * 2)) - 6
                    source: "../assets/glow-green.png"
                    // mostly dark, glowing now and then
                    opacity: Math.max(0, Math.sin(sky.t * blink + phase)) ** 3 * 0.95
                }
            }

            // ── shooting star ──
            Item {
                id: meteor
                property real angle: 24
                opacity: 0
                rotation: angle
                transformOrigin: Item.Right
                width: 190
                height: 2
                Rectangle {
                    anchors.fill: parent
                    radius: 1
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.85; color: Qt.alpha(Theme.text, 0.75) }
                        GradientStop { position: 1.0; color: "white" }
                    }
                }
                Image { source: "../assets/glow-white.png"; width: 14; height: 14; x: parent.width - 8; y: -6 }

                ParallelAnimation {
                    id: fall
                    property real dx: 520
                    NumberAnimation { target: meteor; property: "x"; to: meteor.x + fall.dx; duration: 950; easing.type: Easing.InQuad }
                    NumberAnimation { target: meteor; property: "y"; to: meteor.y + fall.dx * Math.tan(meteor.angle * Math.PI / 180); duration: 950; easing.type: Easing.InQuad }
                    SequentialAnimation {
                        NumberAnimation { target: meteor; property: "opacity"; to: 0.95; duration: 160 }
                        PauseAnimation { duration: 420 }
                        NumberAnimation { target: meteor; property: "opacity"; to: 0; duration: 370 }
                    }
                }
                Timer {
                    running: win.animate
                    repeat: true
                    interval: 40000 + Math.random() * 70000
                    onTriggered: {
                        interval = 40000 + Math.random() * 70000;
                        const b = win.scene.sky;
                        meteor.x = sky.mx(b[0] + Math.random() * (b[2] - b[0]) * 0.55) - meteor.width;
                        meteor.y = sky.my(b[1] + Math.random() * (b[3] - b[1]) * 0.45);
                        fall.start();
                    }
                }
            }

            // ── the date, written down the sky (read right to left) ──
            Row {
                anchors { right: parent.right; rightMargin: 64; top: parent.top; topMargin: 96 }
                layoutDirection: Qt.RightToLeft
                spacing: 18
                opacity: 0.82

                SystemClock { id: clock; precision: SystemClock.Minutes }
                function kanji(n) {
                    const d = ["", "一", "二", "三", "四", "五", "六", "七", "八", "九"];
                    if (n < 10) return d[n];
                    if (n === 10) return "十";
                    if (n < 20) return "十" + d[n - 10];
                    return d[Math.floor(n / 10)] + "十" + d[n % 10];
                }
                readonly property string dateText: kanji(clock.date.getMonth() + 1) + "月" + kanji(clock.date.getDate()) + "日"
                readonly property string dayText: ["日", "月", "火", "水", "木", "金", "土"][clock.date.getDay()] + "曜日"

                Column {
                    spacing: 2
                    Repeater {
                        model: parent.parent.dateText.split("")
                        Text {
                            required property string modelData
                            text: modelData
                            color: Theme.lamp
                            font.family: Theme.jp
                            font.pixelSize: 30
                            font.weight: Font.DemiBold
                            style: Text.Raised
                            styleColor: Qt.alpha(Theme.crust, 0.6)
                        }
                    }
                }
                Column {
                    spacing: 2
                    topPadding: 34
                    Repeater {
                        model: parent.parent.dayText.split("")
                        Text {
                            required property string modelData
                            text: modelData
                            color: Theme.text
                            font.family: Theme.jp
                            font.pixelSize: 19
                            style: Text.Raised
                            styleColor: Qt.alpha(Theme.crust, 0.6)
                        }
                    }
                }
            }
        }
    }
}
