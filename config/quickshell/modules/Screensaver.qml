import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// The screensaver: after a while idle (hypridle → `qs ipc call whisper
// screensaver`), the night fills the screen — a slow drift across the painting,
// more shooting stars, and a small clock that wanders so nothing burns in.
// Any key, click or real mouse movement brings the desktop back.
Variants {
    model: Quickshell.screens.filter(s => !Quickshell.env("WHISPER_ONLY") || s.name === Quickshell.env("WHISPER_ONLY"))

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        readonly property bool on: Desktop.saver && !Locker.locked
        readonly property bool test: Quickshell.env("WHISPER_SAVER_TEST") === "1"   // ignore input (for screenshots)
        property real fade: on ? 1 : 0
        Behavior on fade { NumberAnimation { duration: win.on ? 2200 : 450; easing.type: Easing.InOutSine } }

        visible: on || fade > 0.001
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "whisper-screensaver"
        WlrLayershell.keyboardFocus: on && !test ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        Item {
            id: stage
            anchors.fill: parent
            opacity: win.fade
            focus: win.on
            Keys.onPressed: event => { Desktop.stopSaver(); event.accepted = true; }
            onFocusChanged: if (win.on) forceActiveFocus()

            Rectangle { anchors.fill: parent; color: Theme.crust }

            // ── a slow drift across the painting (80 s each way) ──
            property real drift: 0
            SequentialAnimation on drift {
                running: win.visible
                loops: Animation.Infinite
                NumberAnimation { from: 0; to: 1; duration: 80000; easing.type: Easing.InOutSine }
                NumberAnimation { from: 1; to: 0; duration: 80000; easing.type: Easing.InOutSine }
            }
            Item {
                anchors.fill: parent
                transform: [
                    Scale {
                        origin.x: stage.width / 2; origin.y: stage.height / 2
                        xScale: 1.05 + 0.05 * stage.drift; yScale: xScale
                    },
                    Translate { x: (stage.drift - 0.5) * -70; y: (stage.drift - 0.5) * 18 }
                ]
                Scene {
                    anchors.fill: parent
                    animate: win.visible
                    showDate: false
                    meteorRate: 4
                }
            }

            // soft vignette, so the edges fall away into the night
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.alpha(Theme.crust, 0.45) }
                    GradientStop { position: 0.3; color: "transparent" }
                    GradientStop { position: 0.75; color: "transparent" }
                    GradientStop { position: 1.0; color: Qt.alpha(Theme.crust, 0.6) }
                }
            }

            // ── the wandering clock ──
            SystemClock { id: clock; precision: SystemClock.Minutes }
            Column {
                id: clockBox
                spacing: 2
                opacity: 0.8
                function wander() {
                    const m = 80;
                    x = m + Math.random() * Math.max(0, stage.width - width - 2 * m);
                    y = stage.height * (0.08 + Math.random() * 0.22);
                }
                Component.onCompleted: wander()
                Behavior on opacity { NumberAnimation { duration: 1400; easing.type: Easing.InOutSine } }

                Text {
                    text: Qt.formatTime(clock.date, "HH:mm")
                    color: Theme.lamp
                    font.family: Theme.font
                    font.pixelSize: Math.round(stage.height * 0.06)
                    font.weight: Font.Light
                }
                Text {
                    text: Astro.moonName + "  ·  " + Qt.formatDate(clock.date, "dddd d MMMM")
                    color: Theme.subtext
                    font.family: Theme.font
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }
            }
            // fade out, move, fade in — once a minute
            Timer {
                running: win.visible
                interval: 60000
                repeat: true
                onTriggered: { clockBox.opacity = 0; moveLater.restart(); }
            }
            Timer { id: moveLater; interval: 1500; onTriggered: { clockBox.wander(); clockBox.opacity = 0.8; } }

            // a click or a real move of the mouse (not a nudge of the desk) wakes it
            MouseArea {
                id: waker
                anchors.fill: parent
                enabled: !win.test
                hoverEnabled: true
                cursorShape: win.on ? Qt.BlankCursor : Qt.ArrowCursor
                property point start: Qt.point(-1, -1)
                onPositionChanged: mouse => {
                    if (start.x < 0) { start = Qt.point(mouse.x, mouse.y); return; }
                    if (Math.abs(mouse.x - start.x) + Math.abs(mouse.y - start.y) > 24) Desktop.stopSaver();
                }
                onPressed: Desktop.stopSaver()
                onWheel: Desktop.stopSaver()
                Connections { target: win; function onOnChanged() { waker.start = Qt.point(-1, -1); if (win.on) clockBox.wander(); } }
            }
        }
    }
}
