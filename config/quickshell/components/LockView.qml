import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import qs.services

// What the lock screen shows: the same living night as the wallpaper (lined
// up with it, so locking only adds the clock), a big lamp-lit clock, tonight's
// moon, and a pill of fireflies for the password. Typing goes straight to
// Locker; there is no text field, so no input method can get in the way.
Item {
    id: root

    property var screen: null
    property bool live: true
    // the UI rests after a while; any key or mouse movement wakes it
    property bool awake: true
    property bool entered: false

    focus: true
    Component.onCompleted: { forceActiveFocus(); entered = true; }

    Timer { id: rest; interval: 14000; running: root.awake && Locker.typed.length === 0 && !Locker.busy; onTriggered: root.awake = false }
    function wake() { awake = true; rest.restart(); }
    Connections { target: Locker; function onTyping() { root.wake(); } function onFailed() { root.wake(); shake.restart(); } }

    Keys.onPressed: event => {
        wake();
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) Locker.submit();
        else if (event.key === Qt.Key_Backspace) (event.modifiers & Qt.ControlModifier) ? Locker.clear() : Locker.backspace();
        else if (event.key === Qt.Key_Escape) Locker.clear();
        else if (event.text.length > 0 && event.text.charCodeAt(0) >= 32 && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) Locker.key(event.text);
        event.accepted = true;
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: root.wake()
        onClicked: { root.wake(); root.forceActiveFocus(); }
    }

    // ── the night, exactly where the wallpaper left it ──
    readonly property int wsId: root.screen ? (Hyprland.monitorFor(root.screen)?.activeWorkspace?.id ?? 3) : 3
    Scene {
        anchors.fill: parent
        animate: root.live
        showDate: false
        shift: (3 - Math.max(1, Math.min(5, root.wsId))) * 22
    }

    // a deeper night under the words
    Rectangle {
        anchors.fill: parent
        opacity: root.awake ? 1 : 0.55
        Behavior on opacity { NumberAnimation { duration: 900; easing.type: Easing.InOutQuad } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.alpha(Theme.crust, 0.42) }
            GradientStop { position: 0.35; color: Qt.alpha(Theme.crust, 0.12) }
            GradientStop { position: 0.6; color: Qt.alpha(Theme.crust, 0.18) }
            GradientStop { position: 1.0; color: Qt.alpha(Theme.crust, 0.78) }
        }
    }

    // everything written on the night: floats in when locking, away when unlocking
    Item {
        id: ui
        anchors.fill: parent
        opacity: root.entered && !Locker.unlocking ? 1 : 0
        scale: Locker.unlocking ? 1.04 : 1
        Behavior on opacity { NumberAnimation { duration: Locker.unlocking ? 300 : 700; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

        SystemClock { id: clock; precision: SystemClock.Seconds }

        // ── the clock ──
        Column {
            id: clockCol
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.17 + (root.entered ? 0 : 24)
            Behavior on y { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }
            spacing: 4

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: time.implicitWidth
                height: time.implicitHeight
                Text {
                    id: time
                    text: Qt.formatTime(clock.date, "HH:mm")
                    color: Theme.lamp
                    font.family: Theme.font
                    font.pixelSize: Math.round(root.height * 0.13)
                    font.weight: Font.Light
                    font.letterSpacing: -2
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Qt.alpha(Theme.lamp, 0.55)
                        shadowBlur: 1.0
                        blurMax: 48
                        shadowHorizontalOffset: 0
                        shadowVerticalOffset: 0
                    }
                }
                // the seconds, as a slow firefly under the minutes
                Rectangle {
                    width: 5; height: 5; radius: 2.5
                    color: Theme.lamp
                    y: parent.height - 6
                    x: (parent.width - 5) * clock.date.getSeconds() / 59
                    opacity: 0.7
                    Behavior on x { NumberAnimation { duration: 900; easing.type: Easing.InOutSine } }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14
                Text {
                    function kanji(n) {
                        const d = ["", "一", "二", "三", "四", "五", "六", "七", "八", "九"];
                        if (n < 10) return d[n];
                        if (n === 10) return "十";
                        if (n < 20) return "十" + d[n - 10];
                        return d[Math.floor(n / 10)] + "十" + d[n % 10];
                    }
                    text: kanji(clock.date.getMonth() + 1) + "月" + kanji(clock.date.getDate()) + "日  " + ["日", "月", "火", "水", "木", "金", "土"][clock.date.getDay()] + "曜日"
                    color: Theme.text
                    opacity: 0.85
                    font.family: Theme.jp
                    font.pixelSize: 21
                }
                Text {
                    anchors.baseline: parent.children[0].baseline
                    text: Qt.formatDate(clock.date, "dddd, d MMMM")
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                }
            }

            Item { width: 1; height: 6 }

            // tonight's moon
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 7
                visible: Settings.moon
                Canvas {
                    width: 14; height: 14
                    anchors.verticalCenter: parent.verticalCenter
                    property real phase: Astro.moonPhase
                    onPhaseChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d"), r = 6.5, cx = 7, cy = 7;
                        ctx.reset();
                        ctx.fillStyle = Qt.alpha(Theme.subtext, 0.25);
                        ctx.beginPath(); ctx.arc(cx, cy, r, 0, 2 * Math.PI); ctx.fill();
                        const sgn = phase < 0.5 ? 1 : -1, term = Math.cos(2 * Math.PI * phase);
                        ctx.fillStyle = Theme.lamp;
                        ctx.beginPath();
                        for (let i = 0; i <= 24; i++) { const th = -Math.PI / 2 + Math.PI * i / 24; const px = cx + sgn * r * Math.cos(th), py = cy + r * Math.sin(th); i ? ctx.lineTo(px, py) : ctx.moveTo(px, py); }
                        for (let i = 24; i >= 0; i--) { const th = -Math.PI / 2 + Math.PI * i / 24; ctx.lineTo(cx + sgn * term * r * Math.cos(th), cy + r * Math.sin(th)); }
                        ctx.closePath(); ctx.fill();
                    }
                }
                Text {
                    text: Astro.moonName + " · " + Math.round(Astro.moonLit * 100) + "% lit"
                    color: Theme.subtext
                    opacity: 0.8
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }
            }
        }

        // ── the password: one firefly per letter ──
        Column {
            id: entry
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.835
            spacing: 12
            opacity: root.awake || Locker.typed.length > 0 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Quickshell.env("USER") ?? ""
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: 14
                font.weight: Font.Bold
                font.letterSpacing: 1.5
            }

            Rectangle {
                id: pill
                anchors.horizontalCenter: parent.horizontalCenter
                width: 340
                height: 52
                radius: 26
                color: Qt.alpha(Theme.base, 0.72)
                border.width: 1
                border.color: Locker.message.length ? Qt.alpha(Theme.red, 0.7)
                            : Locker.typed.length ? Qt.alpha(Theme.lamp, 0.45) : Theme.hairline
                Behavior on border.color { ColorAnimation { duration: Theme.normal } }

                transform: Translate { id: shakeT }
                SequentialAnimation {
                    id: shake
                    NumberAnimation { target: shakeT; property: "x"; to: -12; duration: 50 }
                    NumberAnimation { target: shakeT; property: "x"; to: 10; duration: 70 }
                    NumberAnimation { target: shakeT; property: "x"; to: -6; duration: 70 }
                    NumberAnimation { target: shakeT; property: "x"; to: 3; duration: 70 }
                    NumberAnimation { target: shakeT; property: "x"; to: 0; duration: 90 }
                }

                Icon {
                    anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                    icon: Locker.unlocking ? "lock_open" : "lock"
                    size: 19
                    color: Locker.message.length ? Theme.red : Theme.subtext
                }

                Text {
                    anchors.centerIn: parent
                    visible: Locker.typed.length === 0
                    text: Locker.message || "type to unlock"
                    color: Locker.message.length ? Theme.red : Theme.overlay
                    font.family: Theme.font
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Row {
                    id: dots
                    anchors.centerIn: parent
                    spacing: 7
                    Repeater {
                        model: Math.min(Locker.typed.length, 22)
                        Item {
                            width: 9; height: 9
                            Image {
                                anchors.centerIn: parent
                                width: 26; height: 26
                                source: "../assets/glow-warm.png"
                                opacity: 0.55
                            }
                            Rectangle {
                                anchors.fill: parent
                                radius: 4.5
                                color: Theme.lamp
                            }
                            scale: 0
                            Component.onCompleted: scale = 1
                            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                        }
                    }
                    // checking: the fireflies breathe
                    SequentialAnimation on opacity {
                        running: Locker.busy
                        loops: Animation.Infinite
                        onRunningChanged: if (!running) dots.opacity = 1
                        NumberAnimation { to: 0.35; duration: 380; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1; duration: 380; easing.type: Easing.InOutSine }
                    }
                }
            }
        }

        // ── now playing ──
        Rectangle {
            id: music
            readonly property var players: Mpris.players.values.filter(p => !p.dbusName.includes("playerctld"))
            readonly property var player: players.find(p => p.isPlaying) ?? players[0]
            visible: !!player
            anchors { left: parent.left; bottom: parent.bottom; margins: 36 }
            width: 330
            height: 78
            radius: Theme.radius
            color: Qt.alpha(Theme.base, 0.66)
            border.width: 1
            border.color: Theme.hairline
            opacity: root.awake ? 1 : 0.0
            Behavior on opacity { NumberAnimation { duration: 600 } }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 11
                spacing: 12
                ClippingRectangle {
                    Layout.preferredWidth: 56
                    Layout.preferredHeight: 56
                    radius: 11
                    color: Theme.surface1
                    Image { anchors.fill: parent; source: music.player?.trackArtUrl ?? ""; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                    Icon { anchors.centerIn: parent; visible: !(music.player?.trackArtUrl ?? "").length; icon: "music_note"; size: 24; color: Theme.overlay }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Label { Layout.fillWidth: true; text: music.player?.trackTitle || "Unknown"; font.weight: Font.ExtraBold; color: Theme.lamp }
                    Label { Layout.fillWidth: true; text: music.player?.trackArtist || music.player?.identity || ""; color: Theme.subtext; font.pixelSize: 12 }
                }
                IconButton { icon: "skip_previous"; implicitWidth: 30; implicitHeight: 30; enabled: music.player?.canGoPrevious ?? false; onClicked: music.player.previous() }
                IconButton { icon: music.player?.isPlaying ? "pause" : "play_arrow"; active: true; onClicked: music.player.togglePlaying() }
                IconButton { icon: "skip_next"; implicitWidth: 30; implicitHeight: 30; enabled: music.player?.canGoNext ?? false; onClicked: music.player.next() }
            }
        }

        // ── the quiet facts, bottom right ──
        Row {
            anchors { right: parent.right; bottom: parent.bottom; margins: 36 }
            spacing: 18
            opacity: root.awake ? 0.9 : 0.0
            Behavior on opacity { NumberAnimation { duration: 600 } }

            readonly property int fresh: Math.max(0, Notifs.unread - Locker.unreadAtLock)
            Row {
                visible: parent.fresh > 0
                spacing: 6
                Icon { icon: "notifications"; size: 17; color: Theme.lamp; fill: 1 }
                Label { text: parent.parent.fresh + " new"; color: Theme.text }
            }
            Row {
                spacing: 6
                Icon { icon: "keyboard"; size: 17; color: Theme.subtext }
                Label { text: "EN"; color: Theme.subtext }
            }
            Row {
                readonly property var bat: UPower.displayDevice
                readonly property bool charging: bat?.state === UPowerDeviceState.Charging || bat?.state === UPowerDeviceState.FullyCharged || bat?.state === UPowerDeviceState.PendingCharge
                readonly property int pct: Math.round((bat?.percentage ?? 0) * 100)
                visible: bat?.isLaptopBattery ?? false
                spacing: 6
                Icon {
                    icon: parent.charging ? "battery_charging_full" : parent.pct > 80 ? "battery_full" : parent.pct > 50 ? "battery_5_bar" : parent.pct > 20 ? "battery_3_bar" : "battery_alert"
                    size: 17
                    color: !parent.charging && parent.pct <= 20 ? Theme.red : Theme.subtext
                }
                Label { text: parent.pct + "%"; color: Theme.subtext }
            }
        }
    }
}
