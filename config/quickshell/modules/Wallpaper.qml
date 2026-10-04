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

            // ── lit windows: a slow warm breath ──
            Repeater {
                model: win.scene.windows
                Image {
                    required property var modelData
                    width: modelData[2] * sky.s * 2.2
                    height: modelData[3] * sky.s * 2.2
                    x: sky.mx(modelData[0]) - width / 2
                    y: sky.my(modelData[1]) - height / 2
                    source: "../assets/glow-warm.png"
                    opacity: 0.18
                    SequentialAnimation on opacity {
                        running: win.animate
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.32; duration: 3800 + Math.random() * 2500; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0.16; duration: 3800 + Math.random() * 2500; easing.type: Easing.InOutSine }
                    }
                }
            }

            // ── city lights: quick, small shimmer in their own colours ──
            Repeater {
                model: win.scene.city
                Image {
                    required property var modelData
                    readonly property real base: 0.25 + modelData[2] * 0.45
                    width: 9 + modelData[2] * 6
                    height: width
                    x: sky.mx(modelData[0]) - width / 2
                    y: sky.my(modelData[1]) - height / 2
                    source: "../assets/glow-" + modelData[3] + ".png"
                    opacity: base
                    SequentialAnimation on opacity {
                        running: win.animate
                        loops: Animation.Infinite
                        PauseAnimation { duration: Math.random() * 2600 }
                        NumberAnimation { to: base * 0.35; duration: 380 + Math.random() * 900; easing.type: Easing.InOutQuad }
                        NumberAnimation { to: base; duration: 380 + Math.random() * 900; easing.type: Easing.InOutQuad }
                    }
                }
            }

            // ── stars: the painting's own, twinkling slowly ──
            Repeater {
                model: win.scene.stars
                Image {
                    required property var modelData
                    readonly property bool faint: modelData[2] <= 0.18
                    readonly property real base: faint ? 0.32 : 0.45 + modelData[2] * 0.5
                    width: faint ? 9 : 14 + modelData[2] * 10
                    height: width
                    x: sky.mx(modelData[0]) - width / 2
                    y: sky.my(modelData[1]) - height / 2
                    source: "../assets/glow-white.png"
                    opacity: base
                    SequentialAnimation on opacity {
                        running: win.animate
                        loops: Animation.Infinite
                        PauseAnimation { duration: Math.random() * 5000 }
                        NumberAnimation { to: faint ? 0.05 : base * 0.3; duration: 1200 + Math.random() * 2600; easing.type: Easing.InOutSine }
                        NumberAnimation { to: base; duration: 1200 + Math.random() * 2600; easing.type: Easing.InOutSine }
                    }
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
                    width: modelData[2] * sky.s * 2.6
                    height: width
                    x: sky.mx(modelData[0]) - width / 2
                    y: sky.my(modelData[1]) - height / 2
                    source: "../assets/halo.png"
                    opacity: base
                    SequentialAnimation on opacity {
                        id: breath
                        running: win.animate
                        loops: Animation.Infinite
                        NumberAnimation { to: halo.base + 0.12; duration: 5200; easing.type: Easing.InOutSine }
                        NumberAnimation { to: halo.base - 0.04; duration: 5200; easing.type: Easing.InOutSine }
                    }
                    SequentialAnimation {
                        id: flicker
                        NumberAnimation { target: halo; property: "opacity"; to: 0.08; duration: 60 }
                        NumberAnimation { target: halo; property: "opacity"; to: halo.base; duration: 90 }
                        PauseAnimation { duration: 120 }
                        NumberAnimation { target: halo; property: "opacity"; to: 0.14; duration: 50 }
                        NumberAnimation { target: halo; property: "opacity"; to: halo.base + 0.06; duration: 260 }
                    }
                    Timer {
                        running: win.animate && halo.index === 0
                        repeat: true
                        interval: 28000 + Math.random() * 50000
                        onTriggered: { interval = 28000 + Math.random() * 50000; breath.pause(); flicker.start(); resume.start(); }
                    }
                    Timer { id: resume; interval: 700; onTriggered: breath.resume() }
                }
            }

            // ── fireflies in the bushes ──
            Repeater {
                model: 7
                Image {
                    id: fly
                    readonly property var box: win.scene.fireflies
                    function rx() { return sky.mx(box[0] + Math.random() * (box[2] - box[0])); }
                    function ry() { return sky.my(box[1] + Math.random() * (box[3] - box[1])); }
                    width: 13
                    height: 13
                    x: rx()
                    y: ry()
                    source: "../assets/glow-green.png"
                    opacity: 0
                    Behavior on x { NumberAnimation { duration: 5200; easing.type: Easing.InOutSine } }
                    Behavior on y { NumberAnimation { duration: 5200; easing.type: Easing.InOutSine } }
                    Timer {
                        running: win.animate
                        repeat: true
                        interval: 4200 + Math.random() * 2400
                        triggeredOnStart: true
                        onTriggered: { fly.x = fly.rx(); fly.y = fly.ry(); }
                    }
                    SequentialAnimation on opacity {
                        running: win.animate
                        loops: Animation.Infinite
                        PauseAnimation { duration: 600 + Math.random() * 4000 }
                        NumberAnimation { to: 0.95; duration: 700; easing.type: Easing.OutSine }
                        PauseAnimation { duration: 300 + Math.random() * 900 }
                        NumberAnimation { to: 0; duration: 1400; easing.type: Easing.InSine }
                    }
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
