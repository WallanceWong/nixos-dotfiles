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

    // keeps the screen awake while "Stay awake" is on (needs a live surface)
    PanelWindow {
        id: inhibitHost
        screen: Quickshell.screens[0]
        WlrLayershell.namespace: "whisper-inhibit"
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
        WlrLayershell.namespace: "whisper-control"
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

        Rectangle {
            id: sheet
            width: parent.width
            implicitHeight: body.implicitHeight + 32
            height: parent.height
            radius: Theme.radius + 6
            color: Theme.glassStrong
            border.width: 1
            border.color: Qt.alpha(Theme.lamp, 0.22)
            clip: true

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
                        Rectangle {
                            Layout.preferredWidth: 46
                            Layout.preferredHeight: 46
                            radius: 23
                            gradient: Gradient {
                                GradientStop { position: 0; color: Theme.lamp }
                                GradientStop { position: 1; color: Theme.teal }
                            }
                            Icon { anchors.centerIn: parent; icon: "bedtime"; size: 24; fill: 1; color: Theme.base; rotation: -20 }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Label { text: Quickshell.env("USER"); font.pixelSize: 16; font.weight: Font.ExtraBold; color: Theme.lamp }
                            Label { id: uptimeLabel; text: ""; font.pixelSize: 12; color: Theme.subtext }
                            FileView {
                                id: uptimeFile
                                path: "/proc/uptime"
                                onLoaded: {
                                    const s = Math.floor(parseFloat(text().split(" ")[0]));
                                    const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60);
                                    uptimeLabel.text = "up " + (h ? h + "h " : "") + m + "m";
                                }
                            }
                            Connections { target: root; function onOpenChanged() { if (root.open) uptimeFile.reload(); } }
                        }
                        IconButton { icon: "screenshot_region"; tooltip: "Screenshot"; onClicked: { Panels.close(); Quickshell.execDetached(["sh", "-c", "sleep 0.4; " + Theme.dots + "/config/hypr/screenshot.sh region"]); } }
                        IconButton { icon: "lock"; onClicked: Locker.lock() }
                        IconButton { icon: "power_settings_new"; iconColor: Theme.red; onClicked: Panels.show("power") }
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
                            accent: Theme.teal
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
                        accent: Theme.blue
                        onMoved: v => Audio.setMic(v)
                        onIconClicked: Audio.toggleMic()
                    }
                    Slider {
                        Layout.fillWidth: true
                        Layout.rightMargin: 42
                        visible: root.page === "main"
                        icon: "brightness_6"
                        value: Brightness.value
                        accent: Theme.lamp
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
                            subtitle: Settings.sounds ? "soft chimes" : "silent"
                            active: Settings.sounds
                            onToggled: Settings.sounds = !Settings.sounds
                        }
                    }

                    // power profile
                    Rectangle {
                        Layout.fillWidth: true
                        visible: root.page === "main"
                        implicitHeight: 44
                        radius: 22
                        color: Theme.surface0
                        border.width: 1
                        border.color: Theme.hairline
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 4
                            Repeater {
                                model: [
                                    { p: PowerProfile.PowerSaver, icon: "eco", name: "Saver" },
                                    { p: PowerProfile.Balanced, icon: "balance", name: "Balanced" },
                                    { p: PowerProfile.Performance, icon: "bolt", name: "Performance" }
                                ]
                                Rectangle {
                                    required property var modelData
                                    readonly property bool on: PowerProfiles.profile === modelData.p
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: height / 2
                                    color: on ? Qt.alpha(Theme.lamp, 0.18) : ppMouse.containsMouse ? Theme.surface1 : "transparent"
                                    Behavior on color { ColorAnimation { duration: Theme.normal } }
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        Icon { icon: modelData.icon; size: 17; fill: on ? 1 : 0; color: on ? Theme.lamp : Theme.subtext }
                                        Label { text: modelData.name; font.pixelSize: 12; color: on ? Theme.lamp : Theme.subtext }
                                    }
                                    MouseArea { id: ppMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: PowerProfiles.profile = modelData.p }
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
                            Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 58
                                radius: Theme.radiusSmall + 4
                                color: qaMouse.containsMouse ? Theme.surface1 : Theme.surface0
                                border.width: 1
                                border.color: Theme.hairline
                                Behavior on color { ColorAnimation { duration: Theme.fast } }
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 3
                                    Icon { anchors.horizontalCenter: parent.horizontalCenter; icon: modelData.icon; size: 20; color: modelData.name === "Stop" ? Theme.red : Theme.lamp }
                                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.name; font.pixelSize: 11; color: Theme.subtext }
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
                        Label { Layout.fillWidth: true; text: "Notifications"; font.pixelSize: 14; font.weight: Font.ExtraBold; color: Theme.lamp }
                        Label {
                            visible: Notifs.history.count > 0
                            text: "clear"
                            color: clearMouse.containsMouse ? Theme.lamp : Theme.subtext
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
                        Icon { anchors.horizontalCenter: parent.horizontalCenter; icon: "nights_stay"; size: 34; color: Theme.overlay }
                        Label { anchors.horizontalCenter: parent.horizontalCenter; text: "nothing new tonight"; color: Theme.overlay; font.pixelSize: 12 }
                    }
                    Repeater {
                        model: root.page === "main" ? Notifs.history : 0
                        Rectangle {
                            required property var model
                            required property int index
                            Layout.fillWidth: true
                            visible: index < 12
                            implicitHeight: histRow.implicitHeight + 20
                            radius: Theme.radiusSmall + 2
                            color: Theme.surface0
                            border.width: 1
                            border.color: Theme.hairline
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
                        Label {
                            Layout.fillWidth: true
                            text: root.page === "wifi" ? "Wi-Fi" : root.page === "bluetooth" ? "Bluetooth" : "App volume"
                            font.pixelSize: 16
                            font.weight: Font.ExtraBold
                            color: Theme.lamp
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
