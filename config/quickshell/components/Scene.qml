import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.services

// The living night, as two layers of the painting:
//   sky        — moves with the workspaces (depth), carries the stars, the moon,
//                shooting stars and the time-of-night tint
//   foreground — tree, poles, lamps, houses, the two of them and the city; stays put,
//                carries the city lights (which follow your music), lamps, windows, fireflies
// Used by the wallpaper and the lock screen.
Item {
    id: scene

    property bool animate: false        // run the twinkles (only while visible)
    property real shift: 0               // sideways offset of the sky layer, in pixels
    readonly property real maxShift: 44
    property real meteorRate: 1          // shooting stars per usual amount (the screensaver asks for more)
    property bool showDate: true

    FileView { id: sceneFile; path: Theme.dots + "/theme/scene.json"; blockLoading: true }
    readonly property var info: {
        try { return JSON.parse(sceneFile.text()); }
        catch (e) { return ({ image: [6400, 3600], stars: [], city: [], lamps: [], windows: [], fireflies: [0, 0, 1, 1], sky: [0, 0, 1, 1] }); }
    }

    // painting -> screen mapping ("cover"), shared by both layers so they line up
    readonly property real s: Math.max(width / info.image[0], height / info.image[1])
    readonly property real ox: (width - info.image[0] * s) / 2
    readonly property real oy: (height - info.image[1] * s) / 2
    function mx(x) { return ox + x * s; }
    function my(y) { return oy + y * s; }

    // ── one clock for every twinkle (15 fps — slow motion, kind to the battery) ──
    property real t: 0
    Timer { running: scene.animate; interval: 66; repeat: true; onTriggered: { scene.t += 0.066; scene.updateLevel(); } }
    function wave(speed, phase) { return 0.5 + 0.5 * Math.sin(t * speed + phase); }

    // ── music: the city answers whatever is playing ──
    PwNodePeakMonitor {
        id: peaks
        node: Pipewire.defaultAudioSink
        enabled: scene.animate && Settings.musicReactive && Audio.streams.length > 0 && !Audio.muted
    }
    property real level: 0               // smoothed 0..1, quick rise, slow fall
    function updateLevel() {
        const p = peaks.enabled ? Math.min(1, peaks.peak * 1.6) : 0;
        level = p > level ? level + (p - level) * 0.6 : level * 0.86;
    }

    // how visible the stars are right now (a little less at dusk)
    readonly property real starVis: Settings.skyClock ? 1 - Astro.twilight * 0.2 : 1

    // ═════════════════════ sky layer ═════════════════════
    Item {
        id: skyLayer
        width: scene.width
        height: scene.height
        x: Settings.parallax ? scene.shift : 0
        Behavior on x { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }
        // screens narrower than the painting's spare width (16:9) zoom the sky a touch,
        // about the horizon, so the shift never shows an edge
        readonly property real zoom: Math.max(1, (scene.width + 2 * scene.maxShift + 4) / (scene.info.image[0] * scene.s))
        transform: Scale { origin.x: scene.width / 2; origin.y: scene.my(1296); xScale: skyLayer.zoom; yScale: skyLayer.zoom }

        Image {
            x: scene.ox; y: scene.oy
            width: scene.info.image[0] * scene.s
            height: scene.info.image[1] * scene.s
            source: "file://" + Theme.dots + "/wallpapers/layers/sky.jpg"
            sourceSize.height: scene.height
            smooth: true
            cache: false
        }

        // stars: the painting's own, twinkling slowly
        Repeater {
            model: scene.info.stars
            Image {
                required property var modelData
                readonly property bool faint: modelData[2] <= 0.18
                readonly property real base: faint ? 0.32 : 0.45 + modelData[2] * 0.5
                readonly property real speed: 0.7 + Math.random() * 1.6
                readonly property real phase: Math.random() * 6.28
                width: faint ? 9 : 14 + modelData[2] * 10
                height: width
                x: scene.mx(modelData[0]) - width / 2
                y: scene.my(modelData[1]) - height / 2
                source: "../assets/glow-white.png"
                opacity: scene.starVis * base * (faint ? 0.15 + 0.85 * scene.wave(speed, phase) : 0.3 + 0.7 * Math.pow(scene.wave(speed, phase), 0.6))
            }
        }

        // tonight's moon, in its real phase
        Item {
            id: moon
            visible: Settings.moon && Astro.moonLit > 0.02
            readonly property real r: 17
            x: scene.mx(4060) - r
            y: scene.my(430) - r
            width: r * 2
            height: r * 2

            Image {
                anchors.centerIn: parent
                width: moon.r * 9; height: width
                source: "../assets/glow-white.png"
                opacity: 0.12 + 0.3 * Astro.moonLit
            }
            Canvas {
                id: moonCanvas
                anchors.fill: parent
                property real phase: Astro.moonPhase
                onPhaseChanged: requestPaint()
                Component.onCompleted: requestPaint()
                onPaint: {
                    const ctx = getContext("2d");
                    const r = moon.r, cx = r, cy = r;
                    ctx.reset();
                    // the dark part, barely there (earthshine)
                    ctx.fillStyle = Qt.rgba(0.6, 0.7, 0.75, 0.10);
                    ctx.beginPath(); ctx.arc(cx, cy, r, 0, 2 * Math.PI); ctx.fill();
                    // lit part: limb on one side, terminator curve back
                    const waxing = phase < 0.5;
                    const sgn = waxing ? 1 : -1;
                    const term = Math.cos(2 * Math.PI * phase);   // same in both halves; sgn picks the side
                    ctx.fillStyle = "#f4eed2";
                    ctx.beginPath();
                    for (let i = 0; i <= 40; i++) {
                        const th = -Math.PI / 2 + Math.PI * i / 40;
                        const px = cx + sgn * r * Math.cos(th), py = cy + r * Math.sin(th);
                        i === 0 ? ctx.moveTo(px, py) : ctx.lineTo(px, py);
                    }
                    for (let i = 40; i >= 0; i--) {
                        const th = -Math.PI / 2 + Math.PI * i / 40;
                        ctx.lineTo(cx + sgn * term * r * Math.cos(th), cy + r * Math.sin(th));
                    }
                    ctx.closePath();
                    ctx.fill();
                }
            }
        }

        // shooting star
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
                    NumberAnimation { target: meteor; property: "opacity"; to: 0.95 * scene.starVis; duration: 160 }
                    PauseAnimation { duration: 420 }
                    NumberAnimation { target: meteor; property: "opacity"; to: 0; duration: 370 }
                }
            }
            Timer {
                running: scene.animate && Settings.meteors
                repeat: true
                interval: (40000 + Math.random() * 70000) / scene.meteorRate
                onTriggered: {
                    interval = (40000 + Math.random() * 70000) / scene.meteorRate;
                    const b = scene.info.sky;
                    meteor.x = scene.mx(b[0] + Math.random() * (b[2] - b[0]) * 0.55) - meteor.width;
                    meteor.y = scene.my(b[1] + Math.random() * (b[3] - b[1]) * 0.45);
                    fall.start();
                }
            }
        }
    }

    // ═════════════════════ foreground ═════════════════════
    Image {
        x: scene.ox; y: scene.oy
        width: scene.info.image[0] * scene.s
        height: scene.info.image[1] * scene.s
        source: "file://" + Theme.dots + "/wallpapers/layers/foreground.png"
        sourceSize.height: scene.height
        smooth: true
        cache: false
    }

    // ── time of night, over the whole world (under the lights) ──
    // the painting is a night: never lighter than it, a little deeper after
    // midnight, a faint warm edge at dusk and dawn
    Rectangle {
        anchors.fill: parent
        visible: Settings.skyClock
        color: Theme.crust
        opacity: Astro.night * 0.24
    }
    Rectangle {
        visible: Settings.skyClock && Astro.twilight > 0
        x: 0; width: parent.width
        y: scene.my(1100); height: scene.my(2600) - scene.my(1100)
        opacity: Astro.twilight * 0.5
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: Qt.alpha(Theme.red, 0.5) }
            GradientStop { position: 0.68; color: Qt.alpha(Theme.mustard, 0.8) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // the city's glow on the haze, brightening with the music
    Rectangle {
        x: 0; width: parent.width
        y: scene.my(1640); height: scene.my(2330) - scene.my(1640)
        opacity: scene.level * 0.5
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.63; color: Qt.alpha(Theme.teal, 0.8) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // lit windows: a slow warm breath
    Repeater {
        model: scene.info.windows
        Image {
            required property var modelData
            readonly property real speed: 0.5 + Math.random() * 0.4
            readonly property real phase: Math.random() * 6.28
            width: modelData[2] * scene.s * 2.2
            height: modelData[3] * scene.s * 2.2
            x: scene.mx(modelData[0]) - width / 2
            y: scene.my(modelData[1]) - height / 2
            source: "../assets/glow-warm.png"
            opacity: 0.16 + 0.16 * scene.wave(speed, phase)
        }
    }

    // city lights: a quick shimmer, brighter and bigger with the music
    Repeater {
        model: scene.info.city
        Image {
            required property var modelData
            readonly property real base: 0.25 + modelData[2] * 0.45
            readonly property real speed: 2.2 + Math.random() * 3.5
            readonly property real phase: Math.random() * 6.28
            readonly property real react: 0.6 + Math.random() * 0.8      // not every light jumps alike
            width: 9 + modelData[2] * 6 + scene.level * 7 * react
            height: width
            x: scene.mx(modelData[0]) - width / 2
            y: scene.my(modelData[1]) - height / 2
            source: "../assets/glow-" + modelData[3] + ".png"
            opacity: Math.min(1, base * (0.35 + 0.65 * scene.wave(speed, phase)) * (1 + scene.level * 1.3 * react))
        }
    }

    // streetlamps: a slow breath and, rarely, a flicker
    Repeater {
        model: scene.info.lamps
        Image {
            id: halo
            required property var modelData
            required property int index
            readonly property real base: index === 0 ? 0.42 : 0.34
            property real dip: 0
            width: modelData[2] * scene.s * 2.6
            height: width
            x: scene.mx(modelData[0]) - width / 2
            y: scene.my(modelData[1]) - height / 2
            source: "../assets/halo.png"
            opacity: Math.max(0.05, base - 0.04 + 0.16 * scene.wave(0.6, index * 2.1) - dip)
            SequentialAnimation {
                id: flicker
                NumberAnimation { target: halo; property: "dip"; to: 0.38; duration: 60 }
                NumberAnimation { target: halo; property: "dip"; to: 0; duration: 90 }
                PauseAnimation { duration: 120 }
                NumberAnimation { target: halo; property: "dip"; to: 0.3; duration: 50 }
                NumberAnimation { target: halo; property: "dip"; to: 0; duration: 260 }
            }
            Timer {
                running: scene.animate && halo.index === 0
                repeat: true
                interval: 28000 + Math.random() * 50000
                onTriggered: { interval = 28000 + Math.random() * 50000; flicker.start(); }
            }
        }
    }

    // fireflies in the bushes
    Repeater {
        model: Settings.fireflies ? 7 : 0
        Image {
            readonly property var box: scene.info.fireflies
            readonly property real cx: box[0] + Math.random() * (box[2] - box[0])
            readonly property real cy: box[1] + Math.random() * (box[3] - box[1])
            readonly property real rx: (box[2] - box[0]) * (0.08 + Math.random() * 0.12)
            readonly property real ry: (box[3] - box[1]) * (0.06 + Math.random() * 0.1)
            readonly property real speed: 0.12 + Math.random() * 0.15
            readonly property real phase: Math.random() * 6.28
            readonly property real blink: 0.5 + Math.random() * 0.6
            width: 13; height: 13
            x: scene.mx(cx + rx * Math.sin(scene.t * speed + phase)) - 6
            y: scene.my(cy + ry * Math.sin(scene.t * speed * 1.7 + phase * 2)) - 6
            source: "../assets/glow-green.png"
            opacity: Math.max(0, Math.sin(scene.t * blink + phase)) ** 3 * 0.95
        }
    }

    // ── the date, written down the sky (read right to left) ──
    Row {
        visible: scene.showDate
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
