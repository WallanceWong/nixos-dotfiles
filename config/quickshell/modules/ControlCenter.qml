import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.UPower
import qs.services
import qs.components

// Control centre: slides down from the status pill.
Scope {
    id: root

    readonly property bool open: Panels.open === "control"
    property string page: "main"          // main | wifi | bluetooth | mixer
    onOpenChanged: if (!open) page = "main"

    property bool stayAwake: false

    // The profile the daemon is REALLY using. Quickshell's PowerProfiles.profile flips
    // immediately on a write, even when power-profiles-daemon refuses it (e.g. while
    // GameMode pins every core to the performance governor), so ask the daemon.
    property string realProfile: ""
    Process {
        id: profileProbe
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector { onStreamFinished: root.realProfile = text.trim() }
    }
    Timer {
        id: profilePoll
        interval: 1500; repeat: true; triggeredOnStart: true
        running: root.open
        onTriggered: if (!profileProbe.running) profileProbe.running = true
    }

    // keeps the screen awake while "Stay awake" is on (needs a live surface)
    PanelWindow {
        id: inhibitHost
        screen: Quickshell.screens[0]
        WlrLayershell.namespace: "eva-inhibit"
        WlrLayershell.layer: WlrLayer.Bottom
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; left: true }
        implicitWidth: 1
        implicitHeight: 1
        color: "transparent"
        mask: Region {}
        IdleInhibitor { window: inhibitHost; enabled: root.stayAwake }
    }

    PanelWindow {
        id: panel
        screen: Panels.screen
        visible: root.open || sheet.opacity > 0
        WlrLayershell.namespace: "eva-control"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; right: true }
        margins { top: 54; right: 14 }
        implicitWidth: 408
        implicitHeight: Math.min(sheet.implicitHeight, (screen?.height ?? 1200) - 80)
        color: "transparent"

        HyprlandFocusGrab {
            active: root.open
            windows: [panel]
            onCleared: Panels.close()
        }

        Item {
            id: sheet
            width: parent.width
            implicitHeight: body.implicitHeight + 32
            height: parent.height
            clip: true

            HudFrame {
                anchors.fill: parent
                fill: Theme.glassStrong
                stroke: Qt.alpha(Theme.accent, 0.45)
                cut: 18
                ticks: true
            }
            Rectangle { x: 26; y: 0; width: 90; height: 3; color: Theme.accent }

            opacity: root.open ? 1 : 0
            transform: Translate { y: root.open ? 0 : -24 }
            Behavior on opacity { NumberAnimation { duration: Theme.normal; easing.type: Theme.easing } }

            focus: root.open
            Keys.onEscapePressed: root.page === "main" ? Panels.close() : (root.page = "main")

            Flickable {
                anchors.fill: parent
                anchors.margins: 16
                contentHeight: body.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: body
                    width: parent.width
                    spacing: 12

                    // ───────────── header ─────────────
                    RowLayout {
                        Layout.fillWidth: true
                        visible: root.page === "main"
                        spacing: 12
                        Hexagon {
                            Layout.preferredWidth: 50
                            Layout.preferredHeight: 44
                            fill: Theme.accent
                            stroke: Theme.accent
                            Text { anchors.centerIn: parent; text: Theme.magi ? "N" : "01"; color: Theme.crust; font.family: Theme.title; font.weight: Font.Black; font.pixelSize: 20 }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Caps { text: (Theme.magi ? "OPERATOR · " : "PILOT · ") + (Quickshell.env("USER") ?? ""); font.pixelSize: 16; font.weight: Font.Bold; color: Theme.text; font.letterSpacing: 2 }
                            Caps { id: uptimeLabel; text: ""; font.pixelSize: 11; color: Theme.subtext }
                            FileView {
                                id: uptimeFile
                                path: "/proc/uptime"
                                onLoaded: {
                                    const s = Math.floor(parseFloat(text().split(" ")[0]));
                                    const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60);
                                    uptimeLabel.text = (Theme.magi ? "MAGI UPTIME " : "ACTIVE FOR ") + (h ? h + "H " : "") + m + "M";
                                }
                            }
                            Connections { target: root; function onOpenChanged() { if (root.open) uptimeFile.reload(); } }
                        }
                        IconButton { icon: "screenshot_region"; tooltip: "Screenshot"; onClicked: { Panels.close(); Quickshell.execDetached(["sh", "-c", "sleep 0.4; " + Theme.dots + "/config/hypr/screenshot.sh region"]); } }
                        IconButton { icon: "lock"; onClicked: Locker.lock() }
                        IconButton { icon: "power_settings_new"; iconColor: Theme.alert; onClicked: Panels.show("power") }
                    }

                    // ───────────── setup: UNIT-01 / NERV HQ ─────────────
                    RowLayout {
                        Layout.fillWidth: true
                        visible: root.page === "main"
                        spacing: 6
                        Repeater {
                            model: Setups.all
                            Item {
                                id: setupBtn
                                required property var modelData
                                readonly property bool on: Theme.setup === modelData.id
                                Layout.fillWidth: true
                                implicitHeight: 52
                                HudFrame {
                                    anchors.fill: parent
                                    cut: 10
                                    fill: setupBtn.on ? Qt.alpha(setupBtn.modelData.tone, 0.18) : setupMouse.containsMouse ? Theme.surface1 : Qt.alpha(Theme.surface0, 0.9)
                                    stroke: setupBtn.on ? setupBtn.modelData.tone : Theme.hairline
                                    ticks: setupBtn.on
                                    tickColor: setupBtn.modelData.tone
                                }
                                Column {
                                    anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                                    spacing: 1
                                    Caps { text: setupBtn.modelData.name; color: setupBtn.on ? setupBtn.modelData.tone : Theme.text; font.pixelSize: 15; font.weight: Font.Bold; font.letterSpacing: 2.5 }
                                    Caps { text: setupBtn.modelData.subtitle; color: Theme.subtext; font.pixelSize: 10 }
                                }
                                Rectangle {
                                    anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                                    width: 8; height: 8
                                    color: setupBtn.on ? setupBtn.modelData.tone : "transparent"
                                    border.color: setupBtn.on ? setupBtn.modelData.tone : Theme.overlay
                                    border.width: 1.5
                                }
                                MouseArea { id: setupMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Setups.set(setupBtn.modelData.id) }
                            }
                        }
                    }

                    // ───────────── sliders ─────────────
                    RowLayout {
                        Layout.fillWidth: true
                        visible: root.page === "main"
                        spacing: 6
                        Slider {
                            Layout.fillWidth: true
                            icon: Audio.icon
                            value: Audio.volume
                            dimmed: Audio.muted
                            accent: Theme.armour
                            onMoved: v => Audio.setVolume(v)
                            onIconClicked: Audio.toggleMute()
                        }
                        IconButton { icon: "tune"; onClicked: root.page = "mixer" }
                    }
                    Slider {
                        Layout.fillWidth: true
                        Layout.rightMargin: 42
                        visible: root.page === "main"
                        icon: Audio.micMuted ? "mic_off" : "mic"
                        value: Audio.micVolume
                        dimmed: Audio.micMuted
                        accent: Theme.info
                        onMoved: v => Audio.setMic(v)
                        onIconClicked: Audio.toggleMic()
                    }
                    Slider {
                        Layout.fillWidth: true
                        Layout.rightMargin: 42
                        visible: root.page === "main"
                        icon: "brightness_6"
                        value: Brightness.value
                        accent: Theme.accent
                        onMoved: v => Brightness.set(v)
                    }

                    // ───────────── tiles ─────────────
                    GridLayout {
                        Layout.fillWidth: true
                        visible: root.page === "main"
                        columns: 2
                        rowSpacing: 8
                        columnSpacing: 8

                        readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
                        readonly property var net: wifi?.networks?.values?.find(n => n.connected)
                        readonly property var btDevs: Bluetooth.devices.values.filter(d => d.connected)

                        Tile {
                            Layout.fillWidth: true
                            icon: Networking.wifiEnabled ? "wifi" : "wifi_off"
                            title: "Wi-Fi"
                            subtitle: !Networking.wifiEnabled ? "off" : (parent.net?.name ?? "not connected")
                            active: Networking.wifiEnabled && !!parent.net
                            expandable: true
                            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                            onExpand: root.page = "wifi"
                        }
                        Tile {
                            Layout.fillWidth: true
                            icon: Bluetooth.defaultAdapter?.enabled ? "bluetooth" : "bluetooth_disabled"
                            title: "Bluetooth"
                            subtitle: !Bluetooth.defaultAdapter?.enabled ? "off" : parent.btDevs.length ? parent.btDevs[0].name : "on"
                            active: !!Bluetooth.defaultAdapter?.enabled
                            expandable: true
                            onToggled: if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                            onExpand: root.page = "bluetooth"
                        }
                        Tile {
                            Layout.fillWidth: true
                            icon: Settings.dnd ? "do_not_disturb_on" : "notifications"
                            title: "Do not disturb"
                            subtitle: Settings.dnd ? "notifications held" : "off"
                            active: Settings.dnd
                            onToggled: Settings.dnd = !Settings.dnd
                        }
                        Tile {
                            Layout.fillWidth: true
                            icon: "sports_esports"
                            title: "Game mode"
                            subtitle: Settings.gameMode ? "effects off · quiet" : "off"
                            active: Settings.gameMode
                            onToggled: Desktop.setGameMode(!Settings.gameMode)
                        }
                        Tile {
                            Layout.fillWidth: true
                            icon: "coffee"
                            title: "Stay awake"
                            subtitle: root.stayAwake ? "no sleep, no lock" : "off"
                            active: root.stayAwake
                            onToggled: root.stayAwake = !root.stayAwake
                        }
                        Tile {
                            Layout.fillWidth: true
                            icon: Settings.sounds ? "music_note" : "music_off"
                            title: "Sounds"
                            subtitle: Settings.sounds ? (Theme.drama ? "command room" : "quiet clicks") : "silent"
                            active: Settings.sounds
                            onToggled: Settings.sounds = !Settings.sounds
                        }
                    }

                    // power profile
                    Item {
                        Layout.fillWidth: true
                        visible: root.page === "main"
                        implicitHeight: 44
                        HudFrame { anchors.fill: parent; cut: 9; fill: Qt.alpha(Theme.surface0, 0.9); stroke: Theme.hairline }
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 4
                            Repeater {
                                model: [
                                    { p: PowerProfile.PowerSaver, key: "power-saver", icon: "eco", name: "Saver" },
                                    { p: PowerProfile.Balanced, key: "balanced", icon: "balance", name: "Balanced" },
                                    { p: PowerProfile.Performance, key: "performance", icon: "bolt", name: "Performance" }
                                ]
                                Rectangle {
                                    required property var modelData
                                    readonly property bool on: root.realProfile === "" ? PowerProfiles.profile === modelData.p : root.realProfile === modelData.key
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    color: on ? Qt.alpha(Theme.accent, 0.18) : ppMouse.containsMouse ? Theme.surface1 : "transparent"
                                    border.width: on ? 1 : 0
                                    border.color: Qt.alpha(Theme.accent, 0.6)
                                    Behavior on color { ColorAnimation { duration: Theme.normal } }
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        Icon { icon: modelData.icon; size: 17; fill: on ? 1 : 0; color: on ? Theme.accent : Theme.subtext }
                                        Caps { text: modelData.name; font.pixelSize: 12; font.weight: Font.Bold; color: on ? Theme.accent : Theme.subtext }
                                    }
                                    Timer { id: recheck; interval: 500; onTriggered: if (!profileProbe.running) profileProbe.running = true }
                                    MouseArea { id: ppMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { PowerProfiles.profile = modelData.p; recheck.restart(); } }
                                }
                            }
                        }
                    }

                    // quick actions
                    RowLayout {
                        Layout.fillWidth: true
                        visible: root.page === "main"
                        spacing: 6
                        Repeater {
                            model: [
                                { icon: "photo_camera", name: "Shot", run: () => { Panels.close(); Quickshell.execDetached(["sh", "-c", "sleep 0.4; " + Theme.dots + "/config/hypr/screenshot.sh full"]); } },
                                { icon: "draw", name: "Draw", run: () => { Panels.close(); Quickshell.execDetached(["sh", "-c", "sleep 0.4; " + Theme.dots + "/config/hypr/annotate.sh"]); } },
                                { icon: Recorder.recording ? "stop_circle" : "radio_button_checked", name: Recorder.recording ? "Stop" : "Record", run: () => { Panels.close(); Recorder.toggle(true); } },
                                { icon: "colorize", name: "Picker", run: () => { Panels.close(); Quickshell.execDetached(["sh", "-c", "sleep 0.4; " + Theme.dots + "/config/hypr/picker.sh"]); } },
                                { icon: "content_paste", name: "Clipboard", run: () => Panels.launcher("clipboard") }
                            ]
                            Item {
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 58
                                HudFrame { anchors.fill: parent; cut: 8; fill: qaMouse.containsMouse ? Theme.surface1 : Qt.alpha(Theme.surface0, 0.9); stroke: qaMouse.containsMouse ? Qt.alpha(Theme.accent, 0.5) : Theme.hairline }
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 3
                                    Icon { anchors.horizontalCenter: parent.horizontalCenter; icon: modelData.icon; size: 20; color: modelData.name === "Stop" ? Theme.alert : Theme.accent }
                                    Caps { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.name; font.pixelSize: 11; color: Theme.subtext }
                                }
                                MouseArea { id: qaMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData.run() }
                            }
                        }
                    }

                    // notifications
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        visible: root.page === "main"
                        Caps { Layout.fillWidth: true; text: Theme.magi ? "TRANSMISSIONS" : "MESSAGES"; font.pixelSize: 14; font.weight: Font.Bold; font.letterSpacing: 3; color: Theme.accent }
                        Caps {
                            visible: Notifs.history.count > 0
                            text: "CLEAR"
                            color: clearMouse.containsMouse ? Theme.accent : Theme.subtext
                            font.pixelSize: 12
                            MouseArea { id: clearMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.clearHistory() }
                        }
                    }
                    Connections { target: root; function onOpenChanged() { if (root.open) Notifs.unread = 0; } }
                    Column {
                        Layout.fillWidth: true
                        visible: root.page === "main" && Notifs.history.count === 0
                        topPadding: 10
                        bottomPadding: 10
                        spacing: 6
                        Hexagon { anchors.horizontalCenter: parent.horizontalCenter; implicitWidth: 40; stroke: Theme.overlay }
                        Caps { anchors.horizontalCenter: parent.horizontalCenter; text: Theme.magi ? "NO PATTERN DETECTED" : "NOTHING NEW"; color: Theme.overlay; font.pixelSize: 12 }
                    }
                    Repeater {
                        model: root.page === "main" ? Notifs.history : 0
                        Rectangle {
                            required property var model
                            required property int index
                            Layout.fillWidth: true
                            visible: index < 12
                            implicitHeight: histRow.implicitHeight + 20
                            color: Qt.alpha(Theme.surface0, 0.85)
                            border.width: 1
                            border.color: Theme.hairline
                            Rectangle { width: 3; height: parent.height; color: Theme.accent }
                            RowLayout {
                                id: histRow
                                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 10 }
                                spacing: 10
                                IconImage { Layout.preferredWidth: 30; Layout.preferredHeight: 30; Layout.alignment: Qt.AlignTop; source: model.icon }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Label { Layout.fillWidth: true; text: model.summary; font.weight: Font.Bold }
                                        Label {
                                            text: {
                                                const m = Math.floor((Date.now() - model.time) / 60000);
                                                return m < 1 ? "now" : m < 60 ? m + "m" : Math.floor(m / 60) + "h";
                                            }
                                            font.pixelSize: 11
                                            color: Theme.overlay
                                        }
                                    }
                                    Label { Layout.fillWidth: true; visible: model.body.length > 0; text: model.body.replace(/<[^>]*>/g, ""); color: Theme.subtext; font.pixelSize: 12; font.weight: Font.Medium; maximumLineCount: 2; wrapMode: Text.Wrap }
                                }
                            }
                        }
                    }

                    // ───────────── detail pages ─────────────
                    RowLayout {
                        Layout.fillWidth: true
                        visible: root.page !== "main"
                        IconButton { icon: "arrow_back"; onClicked: root.page = "main" }
                        Caps {
                            Layout.fillWidth: true
                            text: root.page === "wifi" ? "WI-FI" : root.page === "bluetooth" ? "BLUETOOTH" : "APP VOLUME"
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            font.letterSpacing: 3
                            color: Theme.accent
                        }
                    }

                    // Wi-Fi networks
                    WifiPage { Layout.fillWidth: true; visible: root.page === "wifi"; active: root.open && root.page === "wifi" }
                    // Bluetooth devices
                    BluetoothPage { Layout.fillWidth: true; visible: root.page === "bluetooth"; active: root.open && root.page === "bluetooth" }
                    // per-app volume
                    MixerPage { Layout.fillWidth: true; visible: root.page === "mixer" }
                }
            }
        }
    }
}
