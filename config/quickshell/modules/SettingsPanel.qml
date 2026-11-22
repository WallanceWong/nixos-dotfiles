import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// Super + , — the knobs of the rice itself: which setup, what the wallpaper
// does, the sounds, and the automations. Everything saves straight away.
PanelWindow {
    id: panel

    readonly property bool open: Panels.open === "settings"
    screen: Panels.screen
    visible: open || veil.opacity > 0
    WlrLayershell.namespace: "eva-settings"
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

    component Section: Caps {
        Layout.topMargin: 8
        font.pixelSize: 13
        font.weight: Font.Bold
        font.letterSpacing: 3
        color: Theme.armour
    }

    Item {
        anchors.centerIn: parent
        width: 720
        height: content.implicitHeight + 52
        opacity: veil.opacity
        scale: 0.96 + 0.04 * veil.opacity
        MouseArea { anchors.fill: parent }
        HudFrame {
            anchors.fill: parent
            fill: Theme.glassStrong
            stroke: Qt.alpha(Theme.accent, 0.5)
            cut: 22
            ticks: true
        }
        Rectangle { x: 34; y: 0; width: 140; height: 3; color: Theme.accent }

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 26 }
            spacing: 10

            RowLayout {
                spacing: 12
                Text { text: "設定"; font.family: Theme.title; font.weight: Font.Black; font.pixelSize: 30; color: Theme.text }
                Caps { text: "SYSTEM CONFIGURATION"; font.pixelSize: 16; font.weight: Font.Bold; font.letterSpacing: 4; color: Theme.accent }
                Item { Layout.fillWidth: true }
                IconButton { icon: "close"; onClicked: Panels.close() }
            }

            Section { text: "SETUP  ·  SUPER + SHIFT + U" }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Repeater {
                    model: Setups.all
                    Item {
                        id: card
                        required property var modelData
                        readonly property bool on: Theme.setup === modelData.id
                        Layout.fillWidth: true
                        implicitHeight: 84
                        HudFrame {
                            anchors.fill: parent
                            cut: 14
                            fill: card.on ? Qt.alpha(card.modelData.tone, 0.16) : cardMouse.containsMouse ? Theme.surface1 : Qt.alpha(Theme.surface0, 0.9)
                            stroke: card.on ? card.modelData.tone : Theme.hairline
                            strokeWidth: card.on ? 1.5 : 1
                            ticks: card.on
                            tickColor: card.modelData.tone
                        }
                        Column {
                            anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                            spacing: 2
                            Caps { text: card.modelData.name; color: card.on ? card.modelData.tone : Theme.text; font.pixelSize: 22; font.weight: Font.Bold; font.letterSpacing: 3 }
                            Caps { text: card.modelData.subtitle; color: Theme.subtext; font.pixelSize: 12 }
                        }
                        Caps {
                            anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                            text: card.on ? "ACTIVE" : Setups.switching ? "…" : "ENGAGE"
                            color: card.on ? card.modelData.tone : Theme.overlay
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            font.letterSpacing: 2
                        }
                        MouseArea { id: cardMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Setups.set(card.modelData.id) }
                    }
                }
            }

            Section { text: "WALLPAPER" }
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 10
                rowSpacing: 10
                Tile { Layout.fillWidth: true; icon: "layers"; title: "Depth"; subtitle: "the painting drifts as you change workspace"; active: Settings.parallax; onToggled: Settings.parallax = !Settings.parallax }
                Tile { Layout.fillWidth: true; icon: "graphic_eq"; title: "Follows music"; subtitle: Theme.magi ? "AT field and signal trace react" : "embers and Unit-01's eye react"; active: Settings.musicReactive; onToggled: Settings.musicReactive = !Settings.musicReactive }
                Tile { Layout.fillWidth: true; icon: "local_fire_department"; title: "Embers"; subtitle: "sparks rising from the shore (UNIT-01)"; active: Settings.embers; onToggled: Settings.embers = !Settings.embers }
                Tile { Layout.fillWidth: true; icon: "calendar_today"; title: "Title-card date"; subtitle: "vertical Mincho date (UNIT-01)"; active: Settings.skyClock; onToggled: Settings.skyClock = !Settings.skyClock }
            }

            Section { text: "SOUND" }
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 10
                rowSpacing: 10
                Tile { Layout.fillWidth: true; icon: "music_note"; title: "Interface sounds"; subtitle: Theme.magi ? "command-room beeps" : "quiet clicks, tape deck"; active: Settings.sounds; onToggled: Settings.sounds = !Settings.sounds }
                Tile { Layout.fillWidth: true; icon: "campaign"; title: "Klaxon"; subtitle: "alarms for critical alerts (NERV HQ)"; active: Settings.klaxon; onToggled: Settings.klaxon = !Settings.klaxon }
                Tile { Layout.fillWidth: true; icon: "wb_sunny"; title: "Cicadas"; subtitle: Ambience.playing ? "the endless summer, very quietly" : Settings.ambience ? "waits for silence" : "Tokyo-3 summer ambience"; active: Settings.ambience; onToggled: Settings.ambience = !Settings.ambience }
                Slider {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    visible: Settings.ambience
                    icon: "wb_sunny"
                    accent: Theme.armour
                    value: Settings.ambienceVolume
                    onMoved: v => Settings.ambienceVolume = v
                }
            }

            Section { text: "DESKTOP" }
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 10
                rowSpacing: 10
                Tile { Layout.fillWidth: true; icon: "monitor"; title: "Screensaver"; subtitle: "the scene fills the screen after 2 min idle"; active: Settings.screensaver; onToggled: Settings.screensaver = !Settings.screensaver }
                Tile { Layout.fillWidth: true; icon: "crop_free"; title: "Cut corners"; subtitle: "45° chamfers on every monitor"; active: Settings.corners; onToggled: Settings.corners = !Settings.corners }
                Tile { Layout.fillWidth: true; icon: "battery_saver"; title: "Battery saver"; subtitle: Automations.saving ? "on now — effects resting" : "below 20%, the wallpaper goes still"; active: Settings.batterySaver; onToggled: Settings.batterySaver = !Settings.batterySaver }
                Tile { Layout.fillWidth: true; icon: "bolt"; title: "Charger-aware power"; subtitle: "performance plugged in, balanced on battery"; active: Settings.autoPower; onToggled: Settings.autoPower = !Settings.autoPower }
                Tile { Layout.fillWidth: true; icon: "emergency"; title: "ThinkPad lights"; subtitle: "lid dot beats on battery, blinks on alerts"; active: Settings.leds; onToggled: Settings.leds = !Settings.leds }
                Tile { Layout.fillWidth: true; icon: "sports_esports"; title: "Auto game mode"; subtitle: "when a game asks for gamemode"; active: Settings.autoGameMode; onToggled: Settings.autoGameMode = !Settings.autoGameMode }
                Tile { Layout.fillWidth: true; icon: "developer_board"; title: "Boards"; subtitle: Automations.board ? "plugged in: " + Automations.board : "Arduino / CH340 watcher"; active: Automations.board !== ""; onToggled: Automations.openBoardApp() }
            }

            Caps {
                Layout.topMargin: 4
                Layout.alignment: Qt.AlignHCenter
                text: "SUPER + /  SHOWS EVERY SHORTCUT"
                color: Theme.overlay
                font.pixelSize: 12
            }
        }
    }
}
