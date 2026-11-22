import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Pipewire
import qs.services

// NERV HQ / MAGI — the command display, all live:
//   left    angel-detection radar, NERV crest
//   centre  the MAGI: CASPER-3, BALTHASAR-2, MELCHIOR-1, each watching a reading
//           (temperature, memory, processor) and voting on the system's state
//   right   SYNC RATIO (CPU) with its trace, LCL density (memory), core temp,
//           and the power panel: EXTERNAL / INTERNAL lamps + the countdown
//   bottom  signal trace (follows your music) and a scrolling status ticker
Item {
    id: scene

    property bool animate: false
    property string screenName: ""
    property bool compact: false        // lock screen / screensaver: fewer panels
    property bool showMagi: true        // the lock screen draws its own, bigger MAGI

    StatsUser { active: scene.animate || scene.visible }

    readonly property bool emergency: Stats.onBattery && Stats.battery <= 0.15
    readonly property color hud: emergency ? Theme.alert : Theme.accent
    readonly property real u: Math.min(width / 1920, height / 1200)   // layout unit

    // ── clocks: one shared tick (15 fps), music level ──
    property real t: 0
    property real level: 0
    property var trace: []
    PwNodePeakMonitor {
        id: peaks
        node: Pipewire.defaultAudioSink
        enabled: scene.animate && Settings.musicReactive && Audio.streams.length > 0 && !Audio.muted
    }
    Timer {
        running: scene.animate
        interval: 66
        repeat: true
        onTriggered: {
            scene.t += 0.066;
            const p = peaks.enabled ? Math.min(1, peaks.peak * 1.6) : 0;
            scene.level = p > scene.level ? scene.level + (p - scene.level) * 0.6 : scene.level * 0.86;
            const tr = scene.trace.slice(-119);
            tr.push(scene.level);
            scene.trace = tr;
        }
    }

    // ═══════════ background: grid + hex field ═══════════
    Rectangle { anchors.fill: parent; color: Theme.crust }
    Canvas {
        id: grid
        anchors.fill: parent
        property color c: Theme.accent
        onCChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const step = 48 * scene.u;
            ctx.strokeStyle = Qt.alpha(c, 0.06);
            ctx.lineWidth = 1;
            ctx.beginPath();
            for (let x = 0; x < width; x += step) { ctx.moveTo(Math.round(x) + 0.5, 0); ctx.lineTo(Math.round(x) + 0.5, height); }
            for (let y = 0; y < height; y += step) { ctx.moveTo(0, Math.round(y) + 0.5); ctx.lineTo(width, Math.round(y) + 0.5); }
            ctx.stroke();
            // brighter crosses on every 4th intersection
            ctx.strokeStyle = Qt.alpha(c, 0.18);
            ctx.beginPath();
            for (let x = 0; x < width; x += step * 4) for (let y = 0; y < height; y += step * 4) {
                ctx.moveTo(x - 5, y + 0.5); ctx.lineTo(x + 6, y + 0.5);
                ctx.moveTo(x + 0.5, y - 5); ctx.lineTo(x + 0.5, y + 6);
            }
            ctx.stroke();
        }
    }
    // hex field (AT field), lower left, breathing with the music
    Canvas {
        id: hexField
        anchors.fill: parent
        property color c: scene.hud
        onCChanged: requestPaint()
        onWidthChanged: requestPaint()
        opacity: 0.35 + 0.15 * Math.sin(scene.t * 0.6) + 0.5 * scene.level
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const r = 26 * scene.u, w = r * 2, h = Math.sqrt(3) * r;
            const cx0 = width * 0.16, cy0 = height * 0.86, reach = width * 0.42;
            for (let col = 0; col * w * 0.75 < width * 0.6; col++) {
                for (let row = -1; row * h < height; row++) {
                    const x = col * w * 0.75, y = row * h + (col % 2 ? h / 2 : 0);
                    const d = Math.hypot(x - cx0, y - cy0) / reach;
                    if (d > 1) continue;
                    ctx.strokeStyle = Qt.alpha(c, 0.22 * (1 - d));
                    ctx.lineWidth = 1.2;
                    ctx.beginPath();
                    for (let i = 0; i <= 6; i++) {
                        const a = Math.PI / 3 * i;
                        const px = x + r * 0.92 * Math.cos(a), py = y + r * 0.92 * Math.sin(a);
                        i === 0 ? ctx.moveTo(px, py) : ctx.lineTo(px, py);
                    }
                    ctx.stroke();
                }
            }
        }
    }
    // scanline sweeping down
    Rectangle {
        width: parent.width
        height: 120 * scene.u
        y: ((scene.t * 70 * scene.u) % (scene.height + height)) - height
        gradient: Gradient {
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.97; color: Qt.alpha(scene.hud, 0.06) }
            GradientStop { position: 1; color: Qt.alpha(scene.hud, 0.16) }
        }
    }

    // ═══════════ pieces ═══════════
    component Tag: Text {
        color: Theme.subtext
        font.family: Theme.hud
        font.pixelSize: 13 * scene.u
        font.weight: Font.DemiBold
        font.letterSpacing: 2 * scene.u
    }
    component Panel: Item {
        id: panel
        property string title: ""
        property string code: ""
        property color tone: scene.hud
        HudFrame {
            anchors.fill: parent
            fill: Qt.alpha(Theme.base, 0.78)
            stroke: Qt.alpha(panel.tone, 0.55)
            cut: 16 * scene.u
            ticks: true
            tickColor: panel.tone
        }
        Rectangle { x: 18 * scene.u; y: 0; width: titleText.implicitWidth + 16 * scene.u; height: 2; color: panel.tone }
        Text {
            id: titleText
            x: 26 * scene.u; y: 10 * scene.u
            text: panel.title
            color: panel.tone
            font.family: Theme.hud
            font.pixelSize: 15 * scene.u
            font.weight: Font.Bold
            font.letterSpacing: 2.5 * scene.u
        }
        Text {
            anchors { right: parent.right; rightMargin: 16 * scene.u; top: parent.top; topMargin: 11 * scene.u }
            text: panel.code
            color: Theme.overlay
            font.family: Theme.mono
            font.pixelSize: 11 * scene.u
        }
    }

    // ═══════════ top left: crest + location ═══════════
    Item {
        id: crest
        x: 56 * scene.u; y: 96 * scene.u
        width: 420 * scene.u; height: 200 * scene.u
        Image {
            id: logo
            source: "../assets/eva/nerv.svg"
            height: 150 * scene.u
            sourceSize.height: height
            fillMode: Image.PreserveAspectFit
            visible: false
        }
        MultiEffect {
            width: logo.width; height: logo.height
            source: logo
            colorization: 1
            colorizationColor: Theme.alert
            opacity: 0.9
        }
        Column {
            x: logo.width + 24 * scene.u
            y: 12 * scene.u
            spacing: 4 * scene.u
            Text { text: "特務機関"; color: Theme.text; font.family: Theme.title; font.weight: Font.Black; font.pixelSize: 34 * scene.u }
            Text { text: "NERV"; color: scene.hud; font.family: Theme.title; font.weight: Font.Black; font.pixelSize: 26 * scene.u; font.letterSpacing: 6 * scene.u }
            Tag { text: "GEOFRONT · TOKYO-3"; topPadding: 6 * scene.u }
            Tag { text: "CENTRAL DOGMA · LEVEL EEE"; color: Theme.overlay }
        }
    }

    // ═══════════ left: angel-detection radar ═══════════
    Item {
        id: radar
        visible: !scene.compact
        x: 70 * scene.u; y: 380 * scene.u
        width: 400 * scene.u; height: width
        readonly property color c: scene.hud
        Canvas {
            anchors.fill: parent
            property color c: radar.c
            onCChanged: requestPaint()
            onWidthChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const r = width / 2;
                ctx.strokeStyle = Qt.alpha(c, 0.35);
                ctx.lineWidth = 1;
                for (let i = 1; i <= 4; i++) { ctx.beginPath(); ctx.arc(r, r, r * i / 4 - 1, 0, 2 * Math.PI); ctx.stroke(); }
                ctx.beginPath();
                ctx.moveTo(0, r); ctx.lineTo(width, r);
                ctx.moveTo(r, 0); ctx.lineTo(r, height);
                ctx.stroke();
                // tick marks around the rim
                ctx.strokeStyle = Qt.alpha(c, 0.6);
                for (let a = 0; a < 360; a += 10) {
                    const rad = a * Math.PI / 180, l = a % 30 === 0 ? 10 : 5;
                    ctx.beginPath();
                    ctx.moveTo(r + (r - 1) * Math.cos(rad), r + (r - 1) * Math.sin(rad));
                    ctx.lineTo(r + (r - 1 - l) * Math.cos(rad), r + (r - 1 - l) * Math.sin(rad));
                    ctx.stroke();
                }
            }
        }
        // the sweep: a pre-drawn wedge, rotated by the GPU
        Canvas {
            id: sweep
            anchors.fill: parent
            property color c: radar.c
            onCChanged: requestPaint()
            onWidthChanged: requestPaint()
            rotation: (scene.t * 40) % 360
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const r = width / 2;
                for (let i = 0; i < 30; i++) {
                    ctx.fillStyle = Qt.alpha(c, 0.22 * (1 - i / 30));
                    ctx.beginPath();
                    ctx.moveTo(r, r);
                    ctx.arc(r, r, r - 2, -i * Math.PI / 90 - Math.PI / 90, -i * Math.PI / 90);
                    ctx.closePath();
                    ctx.fill();
                }
                ctx.strokeStyle = Qt.alpha(c, 0.9);
                ctx.lineWidth = 2;
                ctx.beginPath(); ctx.moveTo(r, r); ctx.lineTo(width - 2, r); ctx.stroke();
            }
        }
        // a blip that lights up as the sweep passes — "no pattern", just a contact
        Rectangle {
            readonly property real ang: 0.9
            readonly property real dist: 0.62
            readonly property real pass: ((scene.t * 40) % 360) * Math.PI / 180
            readonly property real since: ((pass - ang) % (2 * Math.PI) + 2 * Math.PI) % (2 * Math.PI)
            width: 9 * scene.u; height: width; radius: width / 2
            x: radar.width / 2 + Math.cos(ang) * dist * radar.width / 2 - width / 2
            y: radar.height / 2 + Math.sin(ang) * dist * radar.height / 2 - height / 2
            color: Theme.info
            opacity: Math.max(0.1, 1 - since / 3)
        }
        Tag { anchors { top: parent.bottom; topMargin: 10 * scene.u; left: parent.left } text: "ANGEL DETECTION · RANGE 30 KM" }
        Tag {
            anchors { top: parent.bottom; topMargin: 10 * scene.u; right: parent.right }
            text: scene.emergency ? "PATTERN ORANGE" : "PATTERN: NONE"
            color: scene.emergency ? Theme.alert : Theme.signal
        }
    }

    // ═══════════ centre: the MAGI ═══════════
    Item {
        id: magi
        visible: scene.showMagi
        width: 700 * scene.u; height: 640 * scene.u
        x: (scene.width - width) / 2 - 40 * scene.u
        y: 250 * scene.u

        // deliberation: every ~25 s the three computers re-vote, one after another
        property int round: 0
        property real roundStart: 0
        Timer {
            running: scene.animate
            interval: 25000
            repeat: true
            triggeredOnStart: true
            onTriggered: { magi.round++; magi.roundStart = scene.t; }
        }
        function state(i) {
            const dt = scene.t - roundStart;
            const decide = 1.2 + i * 0.9;
            if (dt < decide) return "審議中";          // deliberating
            // a hot or full machine makes its computer reject
            const bad = [Stats.temp > 90, Stats.mem > 0.92, Stats.cpu > 0.95][i];
            return bad || scene.emergency ? "否決" : "承認";
        }

        // links between the three
        Canvas {
            anchors.fill: parent
            property color c: scene.hud
            onCChanged: requestPaint()
            onWidthChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.strokeStyle = Qt.alpha(c, 0.75);
                ctx.lineWidth = 10 * scene.u;
                ctx.beginPath();
                const u = scene.u, cw = 300 * u, ch = 200 * u, by = height - ch - 40 * u;
                ctx.moveTo(width / 2 - 40 * u, ch); ctx.lineTo(cw / 2 + 20 * u, by);
                ctx.moveTo(width / 2 + 40 * u, ch); ctx.lineTo(width - cw / 2 - 20 * u, by);
                ctx.moveTo(cw, by + ch / 2); ctx.lineTo(width - cw, by + ch / 2);
                ctx.stroke();
            }
        }

        Text {
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: -60 * scene.u }
            text: "MAGI SYSTEM"
            color: Theme.text
            font.family: Theme.hud
            font.pixelSize: 28 * scene.u
            font.weight: Font.Bold
            font.letterSpacing: 8 * scene.u
        }
        Text {
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 262 * scene.u }
            text: "MAGI"
            color: Qt.alpha(scene.hud, 0.85)
            font.family: Theme.title
            font.weight: Font.Black
            font.pixelSize: 54 * scene.u
            font.letterSpacing: 8 * scene.u
        }

        component Computer: Item {
            id: comp
            property int index: 0
            property string name: ""
            property string reading: ""
            property real value: 0
            readonly property string vote: magi.state(index)
            readonly property color tone: vote === "承認" ? Theme.signal : vote === "否決" ? Theme.alert : Theme.caution
            width: 300 * scene.u; height: 200 * scene.u
            HudFrame {
                anchors.fill: parent
                fill: Qt.alpha(comp.tone, comp.vote === "審議中" ? 0.10 + 0.08 * Math.sin(scene.t * 8) : 0.16)
                stroke: comp.tone
                strokeWidth: 2
                cut: 22 * scene.u
                cutTopRight: true
                cutBottomLeft: true
            }
            Column {
                anchors.centerIn: parent
                spacing: 4 * scene.u
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: comp.name
                    color: Theme.text
                    font.family: Theme.hud
                    font.pixelSize: 20 * scene.u
                    font.weight: Font.Bold
                    font.letterSpacing: 3 * scene.u
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: comp.vote
                    color: comp.tone
                    font.family: Theme.title
                    font.weight: Font.Black
                    font.pixelSize: 52 * scene.u
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: comp.reading
                    color: Theme.subtext
                    font.family: Theme.mono
                    font.pixelSize: 12 * scene.u
                }
            }
        }
        Computer {
            index: 0; name: "CASPER · 3"
            x: (magi.width - width) / 2; y: 0
            reading: "CORE TEMP " + Math.round(Stats.temp) + "°C"
        }
        Computer {
            index: 1; name: "BALTHASAR · 2"
            x: 0; y: magi.height - height - 40 * scene.u
            reading: "LCL DENSITY " + Math.round(Stats.mem * 100) + "%"
        }
        Computer {
            index: 2; name: "MELCHIOR · 1"
            x: magi.width - width; y: magi.height - height - 40 * scene.u
            reading: "SYNC RATIO " + (Stats.cpu * 100).toFixed(1) + "%"
        }
        Tag {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
            text: "CODE 601 · " + (magi.state(2) === "審議中" ? "DELIBERATING" : "RESOLUTION: " + ([0, 1, 2].filter(i => magi.state(i) === "承認").length >= 2 ? "APPROVED" : "REJECTED"))
            color: scene.hud
        }
    }

    // ═══════════ right column: readouts ═══════════
    Column {
        id: right
        visible: !scene.compact
        x: scene.width - width - 56 * scene.u
        y: 96 * scene.u
        width: 440 * scene.u
        spacing: 18 * scene.u

        // SYNC RATIO — the CPU, with its trace
        Panel {
            width: parent.width; height: 210 * scene.u
            title: "SYNC RATIO"; code: "EVA-01 / CPU"
            Row {
                x: 26 * scene.u; y: 44 * scene.u
                spacing: 8 * scene.u
                SevenSeg {
                    text: (Stats.cpu * 100).toFixed(1).padStart(5, " ")
                    digitHeight: 54 * scene.u
                    color: scene.hud
                }
                Text { text: "%"; color: scene.hud; font.family: Theme.hud; font.pixelSize: 26 * scene.u; font.weight: Font.Bold; anchors.bottom: parent.bottom }
            }
            Canvas {
                x: 26 * scene.u; y: 120 * scene.u
                width: parent.width - 52 * scene.u; height: 70 * scene.u
                property var h: Stats.history
                property color c: scene.hud
                onHChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.strokeStyle = Qt.alpha(c, 0.25);
                    ctx.lineWidth = 1;
                    for (let i = 0; i <= 4; i++) { ctx.beginPath(); ctx.moveTo(0, Math.round(height * i / 4) + 0.5); ctx.lineTo(width, Math.round(height * i / 4) + 0.5); ctx.stroke(); }
                    if (h.length < 2) return;
                    ctx.strokeStyle = c;
                    ctx.lineWidth = 2;
                    ctx.beginPath();
                    for (let i = 0; i < h.length; i++) {
                        const x = width * (i + 60 - h.length) / 59, y = height * (1 - h[i]);
                        i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
                    }
                    ctx.stroke();
                }
            }
        }

        // LCL density + core temperature, as segmented gauges
        Panel {
            width: parent.width; height: 150 * scene.u
            title: "LCL · CORE"; code: "ENTRY PLUG"
            Column {
                x: 26 * scene.u; y: 46 * scene.u
                width: parent.width - 52 * scene.u
                spacing: 16 * scene.u
                Repeater {
                    model: [
                        { name: "LCL DENSITY", value: Stats.mem, text: Stats.memText },
                        { name: "CORE TEMP", value: Math.max(0, Math.min(1, (Stats.temp - 30) / 70)), text: Math.round(Stats.temp) + " °C" }
                    ]
                    Column {
                        id: gauge
                        required property var modelData
                        width: parent.width
                        spacing: 6 * scene.u
                        Item {
                            width: parent.width; height: 16 * scene.u
                            Tag { text: gauge.modelData.name; anchors.left: parent.left }
                            Text { text: gauge.modelData.text; anchors.right: parent.right; color: Theme.text; font.family: Theme.mono; font.pixelSize: 12 * scene.u }
                        }
                        Row {
                            spacing: 2
                            Repeater {
                                model: 40
                                Rectangle {
                                    required property int index
                                    readonly property real f: (index + 0.5) / 40
                                    width: (gauge.width - 39 * 2) / 40
                                    height: 12 * scene.u
                                    color: f <= gauge.modelData.value ? (f > 0.85 ? Theme.alert : f > 0.65 ? Theme.caution : scene.hud) : Qt.alpha(Theme.overlay, 0.25)
                                }
                            }
                        }
                    }
                }
            }
        }

        // POWER — umbilical cable or internal battery, with the countdown
        Panel {
            id: powerPanel
            width: parent.width; height: 250 * scene.u
            title: "POWER SUPPLY"; code: "主電源供給システム"
            tone: Stats.onBattery ? Theme.alert : scene.hud
            Row {
                x: 26 * scene.u; y: 48 * scene.u
                spacing: 10 * scene.u
                Repeater {
                    model: [
                        { kanji: "外部", name: "EXTERNAL", on: !Stats.onBattery },
                        { kanji: "内部", name: "INTERNAL", on: Stats.onBattery }
                    ]
                    Rectangle {
                        required property var modelData
                        width: (powerPanel.width - 62 * scene.u) / 2
                        height: 58 * scene.u
                        color: modelData.on ? (modelData.name === "INTERNAL" ? Theme.alert : Theme.signal) : Qt.alpha(Theme.overlay, 0.18)
                        Column {
                            anchors.centerIn: parent
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.kanji; color: modelData.on ? Theme.crust : Theme.overlay; font.family: Theme.title; font.weight: Font.Black; font.pixelSize: 24 * scene.u }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.name; color: modelData.on ? Theme.crust : Theme.overlay; font.family: Theme.hud; font.weight: Font.Bold; font.pixelSize: 11 * scene.u; font.letterSpacing: 2 * scene.u }
                        }
                    }
                }
            }
            Tag {
                x: 26 * scene.u; y: 120 * scene.u
                text: Stats.onBattery ? "ACTIVE TIME REMAINING" : Stats.charging ? "UMBILICAL CABLE · CHARGING" : "UMBILICAL CABLE CONNECTED"
                color: Stats.onBattery ? Theme.alert : Theme.subtext
            }
            Row {
                x: 26 * scene.u; y: 146 * scene.u
                spacing: 14 * scene.u
                SevenSeg {
                    text: Stats.onBattery || Stats.charging ? Stats.clock(Stats.countdown) : "--:--:--"
                    digitHeight: 64 * scene.u
                    color: Stats.onBattery ? Theme.alert : scene.hud
                    dim: 0.12
                }
                Text {
                    anchors.bottom: parent.bottom
                    text: Math.round(Stats.battery * 100) + "%"
                    color: Theme.text
                    font.family: Theme.mono
                    font.pixelSize: 18 * scene.u
                    font.weight: Font.Bold
                }
            }
        }
    }

    // ═══════════ bottom: signal trace + ticker ═══════════
    Item {
        id: bottom
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 56 * scene.u; rightMargin: 56 * scene.u; bottomMargin: 34 * scene.u }
        height: 110 * scene.u

        Canvas {
            id: wave
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 70 * scene.u
            property var tr: scene.trace
            property color c: Theme.signal
            onTrChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.strokeStyle = Qt.alpha(c, 0.18);
                ctx.lineWidth = 1;
                ctx.beginPath(); ctx.moveTo(0, height / 2 + 0.5); ctx.lineTo(width, height / 2 + 0.5); ctx.stroke();
                ctx.strokeStyle = c;
                ctx.lineWidth = 1.6;
                ctx.beginPath();
                const n = 240;
                for (let i = 0; i <= n; i++) {
                    const x = width * i / n;
                    const k = Math.floor(tr.length * i / n);
                    const amp = (tr[k] ?? 0) * height * 0.45 + 1.5;
                    const y = height / 2 + Math.sin(i * 0.55 + scene.t * 6) * amp;
                    i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
                }
                ctx.stroke();
            }
        }
        Rectangle { anchors { left: parent.left; right: parent.right; top: wave.bottom; topMargin: 8 * scene.u } height: 1; color: Qt.alpha(scene.hud, 0.5) }
        Item {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 22 * scene.u
            clip: true
            Text {
                id: ticker
                // the real MAGI log (services/EventLog.qml), then the live readings
                readonly property string msg: "  ◆  " + EventLog.entries.slice(0, 8).map(e => EventLog.stamp(e) + " " + e.text).join("  ◆  ")
                                           + (scene.emergency ? "  ◆  WARNING · INTERNAL POWER CRITICAL · EVACUATE NON-ESSENTIAL PERSONNEL" : "")
                                           + "  ◆  SYNC " + (Stats.cpu * 100).toFixed(1) + "%  ◆  LCL " + Math.round(Stats.mem * 100) + "%  ◆  CORE " + Math.round(Stats.temp) + "°C  ◆  GOD'S IN HIS HEAVEN · ALL'S RIGHT WITH THE WORLD"
                text: msg + msg
                color: scene.hud
                font.family: Theme.mono
                font.pixelSize: 13 * scene.u
                x: -((scene.t * 60 * scene.u) % (implicitWidth / 2))
            }
        }
    }

    // ═══════════ corner furniture ═══════════
    Brackets { anchors.margins: 20 * scene.u; color: Qt.alpha(scene.hud, 0.6); size: 26 * scene.u; weight: 2 }
}
