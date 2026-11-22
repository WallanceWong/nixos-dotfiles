import QtQuick
import QtQuick.Particles
import Quickshell
import Quickshell.Services.Pipewire
import qs.services

// UNIT-01 / SHINJI — the living painting: Shinji at the railing, Unit-01
// rising out of the sea. Embers drift up from the burning shore, Unit-01's eye
// breathes (and flares with your music), sea haze rolls past, the vertical
// date sits in heavy Mincho like a title card.
Item {
    id: scene

    property bool animate: false
    property real shift: 0              // parallax, pixels
    readonly property real maxShift: 44
    property bool showDate: true
    property bool showCaption: true
    property url eyeGlow: "../assets/glow-red.png"
    property real eyeBoost: 0           // the lock screen lights the eye up more
    // where Unit-01's eye is on screen (the lock screen hangs things off it)
    readonly property point eyeOnScreen: Qt.point(layer.x + ox + eye.x * s, oy + eye.y * s)

    // the painting (2240×1454) and where things are in it
    readonly property size image: Qt.size(2240, 1454)
    readonly property point eye: Qt.point(1775, 390)

    // cover + a touch of zoom so the parallax never shows an edge
    readonly property real s: Math.max((width + 2 * maxShift) / image.width, height / image.height)
    readonly property real ox: (width - image.width * s) / 2
    readonly property real oy: (height - image.height * s) / 2

    // ── music level (quick rise, slow fall) ──
    PwNodePeakMonitor {
        id: peaks
        node: Pipewire.defaultAudioSink
        enabled: scene.animate && Settings.musicReactive && Audio.streams.length > 0 && !Audio.muted
    }
    property real level: 0
    property real t: 0
    Timer {
        running: scene.animate
        interval: 66
        repeat: true
        onTriggered: {
            scene.t += 0.066;
            const p = peaks.enabled ? Math.min(1, peaks.peak * 1.6) : 0;
            scene.level = p > scene.level ? scene.level + (p - scene.level) * 0.6 : scene.level * 0.86;
        }
    }

    Item {
        id: layer
        width: scene.width
        height: scene.height
        x: Settings.parallax ? scene.shift : 0
        Behavior on x { NumberAnimation { duration: 1100; easing.type: Easing.OutCubic } }

        Image {
            x: scene.ox; y: scene.oy
            width: scene.image.width * scene.s
            height: scene.image.height * scene.s
            source: "file://" + Theme.dots + "/wallpapers/unit01/wall.jpg"
            sourceSize.width: width
            smooth: true
            mipmap: true
            cache: false
        }

        // Unit-01's eye: a soft pink-red glow that breathes
        Image {
            readonly property real breathe: 0.5 + 0.5 * Math.sin(scene.t * 0.9)
            width: (90 + 50 * scene.level + 160 * scene.eyeBoost) * scene.s * 1.4
            height: width
            x: scene.ox + scene.eye.x * scene.s - width / 2
            y: scene.oy + scene.eye.y * scene.s - height / 2
            source: scene.eyeGlow
            opacity: Math.min(1, 0.35 + 0.35 * breathe + 0.3 * scene.level + 0.4 * scene.eyeBoost)
        }
        Image {
            width: 34 * scene.s * 1.4
            height: width
            x: scene.ox + scene.eye.x * scene.s - width / 2
            y: scene.oy + scene.eye.y * scene.s - height / 2
            source: "../assets/glow-white.png"
            opacity: 0.25 + 0.5 * scene.level + 0.5 * scene.eyeBoost
        }
    }

    // sea haze drifting past, low over the water (two slow bands)
    Repeater {
        model: 2
        Rectangle {
            required property int index
            width: scene.width * 1.6
            height: scene.height * 0.32
            y: scene.height * (0.42 + index * 0.16)
            x: -scene.width * 0.3 + Math.sin(scene.t * (0.05 + index * 0.03) + index * 2) * scene.width * 0.25
            opacity: 0.10 + 0.04 * Math.sin(scene.t * 0.2 + index)
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.5; color: index === 0 ? "#e8eef6" : "#c9d8ea" }
                GradientStop { position: 1; color: "transparent" }
            }
        }
    }

    // embers rising from the burning shore, more when the music is loud
    ParticleSystem {
        id: sparks
        anchors.fill: parent
        running: scene.animate
        paused: !scene.animate
    }
    Emitter {
        system: sparks
        x: 0; y: scene.height * 0.78
        width: scene.width * 0.75; height: scene.height * 0.22
        emitRate: 5 + 30 * scene.level
        lifeSpan: 6500; lifeSpanVariation: 2500
        size: 10; sizeVariation: 8; endSize: 2
        velocity: AngleDirection { angle: -80; angleVariation: 25; magnitude: 38; magnitudeVariation: 24 }
        acceleration: AngleDirection { angle: -60; angleVariation: 40; magnitude: 4 }
    }
    Wander { system: sparks; xVariance: 40; pace: 30; affectedParameter: Wander.Velocity }
    ImageParticle {
        system: sparks
        source: "../assets/glow-warm.png"
        color: "#ffb070"
        colorVariation: 0.15
        alpha: 0.85
        alphaVariation: 0.2
        entryEffect: ImageParticle.Fade
    }

    // a soft vignette so the HUD stays readable
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.alpha(Theme.crust, 0.45) }
            GradientStop { position: 0.12; color: "transparent" }
            GradientStop { position: 0.8; color: "transparent" }
            GradientStop { position: 1; color: Qt.alpha(Theme.crust, 0.55) }
        }
    }

    // ── vertical date, title-card Mincho (top right) ──
    SystemClock { id: clock; precision: SystemClock.Minutes }
    Row {
        visible: scene.showDate && Settings.skyClock
        anchors { right: parent.right; rightMargin: 46; top: parent.top; topMargin: 86 }
        spacing: 10
        layoutDirection: Qt.RightToLeft
        readonly property var kanjiNum: ["〇", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
        function kanji(n) {
            if (n <= 10) return kanjiNum[n];
            if (n < 20) return "十" + kanjiNum[n - 10];
            return kanjiNum[Math.floor(n / 10)] + "十" + (n % 10 ? kanjiNum[n % 10] : "");
        }
        Text {
            text: (parent.kanji(clock.date.getMonth() + 1) + "月" + parent.kanji(clock.date.getDate()) + "日").split("").join("\n")
            color: "#ffffff"
            font.family: Theme.title
            font.weight: Font.Black
            font.pixelSize: 40
            lineHeight: 0.98
            style: Text.Outline
            styleColor: Qt.alpha(Theme.crust, 0.35)
        }
        Text {
            text: ["日", "月", "火", "水", "木", "金", "土"][clock.date.getDay()] + "\n曜\n日"
            color: Qt.alpha("#ffffff", 0.8)
            font.family: Theme.title
            font.weight: Font.Bold
            font.pixelSize: 18
            topPadding: 4
        }
    }

    // ── a quiet caption, bottom left ──
    Column {
        visible: scene.showCaption
        anchors { left: parent.left; leftMargin: 46; bottom: parent.bottom; bottomMargin: 40 }
        spacing: 2
        Text {
            text: "EVANGELION"
            color: Qt.alpha("#ffffff", 0.92)
            font.family: Theme.title
            font.weight: Font.Black
            font.pixelSize: 30
            font.letterSpacing: -1
            transform: Scale { xScale: 0.82 }
        }
        Text {
            text: "TEST TYPE · 初号機"
            color: Theme.accent
            font.family: Theme.hud
            font.weight: Font.Bold
            font.pixelSize: 13
            font.letterSpacing: 3
        }
    }
}
