import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// Super + , — the knobs of the rice itself: what the living night does,
// the sounds, and the automations. Everything saves straight away.
PanelWindow {
    id: panel

    readonly property bool open: Panels.open === "settings"
    screen: Panels.screen
    visible: open || veil.opacity > 0
    WlrLayershell.namespace: "whisper-settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    onOpenChanged: if (open) keys.forceActiveFocus()

    Rectangle {
        id: veil
        anchors.fill: parent
        color: Qt.alpha(Theme.crust, 0.55)
        opacity: panel.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.normal; easing.type: Theme.easing } }
        MouseArea { anchors.fill: parent; onClicked: Panels.close() }
    }

    Item { id: keys; focus: panel.open; Keys.onEscapePressed: Panels.close() }

    component Section: Label {
        Layout.topMargin: 6
        font.pixelSize: 12
        font.weight: Font.ExtraBold
        font.letterSpacing: 1.2
        color: Theme.teal
    }

    Rectangle {
        anchors.centerIn: parent
        width: 680
        height: content.implicitHeight + 52
        radius: Theme.radius + 6
        color: Theme.glassStrong
        border.width: 1
        border.color: Theme.hairline
        opacity: veil.opacity
        scale: 0.96 + 0.04 * veil.opacity
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 26 }
            spacing: 10

            RowLayout {
                spacing: 12
                Icon { icon: "tune"; size: 26; color: Theme.lamp; fill: 1 }
                Label { text: "whisper"; font.pixelSize: 22; font.weight: Font.ExtraBold; color: Theme.lamp }
                Label { text: "how the night behaves"; color: Theme.subtext; font.pixelSize: 13 }
                Item { Layout.fillWidth: true }
                IconButton { icon: "close"; onClicked: Panels.close() }
            }

            Section { text: "THE SCENE" }
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 10
                rowSpacing: 10
                Tile { Layout.fillWidth: true; icon: "layers"; title: "Depth"; subtitle: "the sky drifts as you change workspace"; active: Settings.parallax; onToggled: Settings.parallax = !Settings.parallax }
                Tile { Layout.fillWidth: true; icon: "graphic_eq"; title: "City follows music"; subtitle: "lights and glow pulse with what's playing"; active: Settings.musicReactive; onToggled: Settings.musicReactive = !Settings.musicReactive }
                Tile { Layout.fillWidth: true; icon: "dark_mode"; title: "Tonight's moon"; subtitle: Astro.moonName + " · " + Math.round(Astro.moonLit * 100) + "% lit"; active: Settings.moon; onToggled: Settings.moon = !Settings.moon }
                Tile { Layout.fillWidth: true; icon: "schedule"; title: "Sky follows the clock"; subtitle: "sun " + (Astro.sunAltitude >= 0 ? "up " : "down ") + Math.abs(Math.round(Astro.sunAltitude)) + "° over Kuching"; active: Settings.skyClock; onToggled: Settings.skyClock = !Settings.skyClock }
                Tile { Layout.fillWidth: true; icon: "auto_awesome"; title: "Shooting stars"; subtitle: "one every minute or two"; active: Settings.meteors; onToggled: Settings.meteors = !Settings.meteors }
                Tile { Layout.fillWidth: true; icon: "flare"; title: "Fireflies"; subtitle: "in the bushes by the house"; active: Settings.fireflies; onToggled: Settings.fireflies = !Settings.fireflies }
            }

            Section { text: "SOUND" }
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 10
                rowSpacing: 10
                Tile { Layout.fillWidth: true; icon: "music_note"; title: "Interface sounds"; subtitle: "soft ticks and chimes"; active: Settings.sounds; onToggled: Settings.sounds = !Settings.sounds }
                Tile { Layout.fillWidth: true; icon: "nights_stay"; title: "Night ambience"; subtitle: Ambience.playing ? "crickets and the far-off city" : Settings.ambience ? "waits for silence" : "crickets, very quietly"; active: Settings.ambience; onToggled: Settings.ambience = !Settings.ambience }
            }
            Slider {
                Layout.fillWidth: true
                visible: Settings.ambience
                icon: "nights_stay"
                accent: Theme.teal
                value: Settings.ambienceVolume
                onMoved: v => Settings.ambienceVolume = v
            }

            Section { text: "DESKTOP" }
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 10
                rowSpacing: 10
                Tile { Layout.fillWidth: true; icon: "nightlight"; title: "Screensaver"; subtitle: "the night fills the screen after 2 min idle"; active: Settings.screensaver; onToggled: Settings.screensaver = !Settings.screensaver }
                Tile { Layout.fillWidth: true; icon: "rounded_corner"; title: "Rounded screen"; subtitle: "soft corners on every monitor"; active: Settings.corners; onToggled: Settings.corners = !Settings.corners }
                Tile { Layout.fillWidth: true; icon: "battery_saver"; title: "Battery saver"; subtitle: Automations.saving ? "on now — effects resting" : "below 20%, the night goes still"; active: Settings.batterySaver; onToggled: Settings.batterySaver = !Settings.batterySaver }
                Tile { Layout.fillWidth: true; icon: "bolt"; title: "Charger-aware power"; subtitle: "performance plugged in, balanced on battery"; active: Settings.autoPower; onToggled: Settings.autoPower = !Settings.autoPower }
                Tile { Layout.fillWidth: true; icon: "sports_esports"; title: "Auto game mode"; subtitle: "when a game asks for gamemode"; active: Settings.autoGameMode; onToggled: Settings.autoGameMode = !Settings.autoGameMode }
                Tile { Layout.fillWidth: true; icon: "developer_board"; title: "Boards"; subtitle: Automations.board ? "plugged in: " + Automations.board : "Arduino / CH340 watcher"; active: Automations.board !== ""; onToggled: Automations.openBoardApp() }
            }

            Label {
                Layout.topMargin: 4
                Layout.alignment: Qt.AlignHCenter
                text: "Super + /  shows every shortcut"
                color: Theme.overlay
                font.pixelSize: 12
            }
        }
    }
}
