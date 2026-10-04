import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Bluetooth
import Quickshell.Networking
import qs.services
import qs.components

// The bar: little lit windows floating over the city.
Variants {
    // WHISPER_ONLY limits the shell to one screen (used for testing)
    model: Quickshell.screens.filter(s => !Quickshell.env("WHISPER_ONLY") || s.name === Quickshell.env("WHISPER_ONLY"))

    PanelWindow {
        id: bar
        required property var modelData
        screen: modelData

        WlrLayershell.namespace: "whisper-bar"
        WlrLayershell.layer: WlrLayer.Top
        anchors { top: true; left: true; right: true }
        implicitHeight: 54
        exclusiveZone: 48
        color: "transparent"

        readonly property var monitor: Hyprland.monitorFor(modelData)

        // ── left: moon, stars, window title ──
        Row {
            anchors { left: parent.left; leftMargin: 14; top: parent.top; topMargin: 8 }
            spacing: 6

            Pill {
                width: 42
                hovered: moonMouse.containsMouse
                highlighted: Panels.open === "launcher"
                Icon { anchors.centerIn: parent; icon: "bedtime"; size: 20; fill: 1; color: Theme.lamp; rotation: -20 }
                MouseArea { id: moonMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Panels.launcher("apps") }
            }

            Pill {
                width: stars.implicitWidth + 16
                Row {
                    id: stars
                    anchors.centerIn: parent
                    spacing: 2
                    Repeater {
                        model: 5
                        Item {
                            id: star
                            required property int index
                            readonly property int wsId: index + 1
                            readonly property var ws: Hyprland.workspaces.values.find(w => w.id === wsId)
                            readonly property bool active: bar.monitor?.activeWorkspace?.id === wsId
                            readonly property bool occupied: (ws?.toplevels?.values?.length ?? 0) > 0
                            width: 26; height: 30
                            Icon {
                                anchors.centerIn: parent
                                icon: "star"
                                size: star.active ? 21 : 17
                                fill: star.active || star.occupied ? 1 : 0
                                color: star.ws?.urgent ? Theme.red
                                     : star.active ? Theme.lamp
                                     : wsMouse.containsMouse ? Theme.teal
                                     : star.occupied ? Theme.subtext : Qt.alpha(Theme.overlay, 0.9)
                                Behavior on size { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutBack } }
                            }
                            MouseArea {
                                id: wsMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Hyprland.dispatch("workspace " + star.wsId)
                            }
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: e => Hyprland.dispatch("workspace " + (e.angleDelta.y > 0 ? "e-1" : "e+1"))
                }
            }

            Pill {
                readonly property string title: Hyprland.activeToplevel?.workspace?.id === bar.monitor?.activeWorkspace?.id ? (Hyprland.activeToplevel?.title ?? "") : ""
                width: Math.min(titleText.implicitWidth + 28, 380)
                Label {
                    id: titleText
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    text: parent.title.length ? parent.title : "quiet night"
                    color: parent.title.length ? Theme.subtext : Theme.overlay
                    font.weight: Font.Medium
                }
            }
        }

        // ── centre: the clock ──
        Pill {
            id: clockPill
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 8 }
            width: clockRow.implicitWidth + 32
            hovered: clockMouse.containsMouse
            highlighted: Panels.open === "dashboard"
            border.color: Qt.alpha(Theme.lamp, highlighted ? 0.5 : 0.25)
            SystemClock { id: clock; precision: SystemClock.Minutes }
            Row {
                id: clockRow
                anchors.centerIn: parent
                spacing: 10
                Label { text: Qt.formatTime(clock.date, "HH:mm"); color: Theme.lamp; font.pixelSize: 15; font.weight: Font.ExtraBold }
                Label { text: Qt.formatDate(clock.date, "ddd d MMM"); color: Theme.subtext; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
            }
            MouseArea { id: clockMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Panels.toggle("dashboard") }
        }

        // ── right: recording, media, tray, status, power ──
        Row {
            anchors { right: parent.right; rightMargin: 14; top: parent.top; topMargin: 8 }
            spacing: 6

            // recording indicator
            Pill {
                id: recPill
                visible: Recorder.recording
                width: recRow.implicitWidth + 26
                color: Qt.alpha(Theme.red, 0.22)
                border.color: Qt.alpha(Theme.red, 0.6)
                property int secs: 0
                Timer { running: Recorder.recording; interval: 1000; repeat: true; triggeredOnStart: true; onTriggered: recPill.secs = Math.floor((Date.now() - Recorder.startedAt) / 1000) }
                Row {
                    id: recRow
                    anchors.centerIn: parent
                    spacing: 7
                    Rectangle {
                        width: 9; height: 9; radius: 5; color: Theme.red
                        anchors.verticalCenter: parent.verticalCenter
                        SequentialAnimation on opacity { running: Recorder.recording; loops: Animation.Infinite; NumberAnimation { to: 0.25; duration: 700 } NumberAnimation { to: 1; duration: 700 } }
                    }
                    Label { text: "REC " + Math.floor(recPill.secs / 60) + ":" + String(recPill.secs % 60).padStart(2, "0"); color: Theme.red; font.weight: Font.Bold }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Recorder.toggle(false) }
            }

            // now playing
            Pill {
                id: media
                readonly property var players: Mpris.players.values.filter(p => !p.dbusName.includes("playerctld"))
                    readonly property var player: players.find(p => p.isPlaying) ?? players[0]
                visible: !!player && (player.trackTitle ?? "").length > 0
                width: mediaRow.implicitWidth + 26
                hovered: mediaMouse.containsMouse
                Row {
                    id: mediaRow
                    anchors.centerIn: parent
                    spacing: 7
                    Icon { icon: media.player?.isPlaying ? "graphic_eq" : "music_note"; size: 17; color: Theme.teal; fill: 1 }
                    Label {
                        text: (media.player?.trackTitle ?? "") + ((media.player?.trackArtist ?? "").length ? "  ·  " + media.player.trackArtist : "")
                        width: Math.min(implicitWidth, 260)
                        color: Theme.teal
                        font.weight: Font.Medium
                    }
                }
                MouseArea {
                    id: mediaMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onClicked: e => e.button === Qt.MiddleButton ? media.player?.togglePlaying() : Panels.toggle("dashboard")
                }
            }

            // system tray
            Pill {
                visible: SystemTray.items.values.length > 0
                width: trayRow.implicitWidth + 22
                Row {
                    id: trayRow
                    anchors.centerIn: parent
                    spacing: 10
                    Repeater {
                        model: SystemTray.items
                        IconImage {
                            id: trayIcon
                            required property var modelData
                            implicitSize: 18
                            source: modelData.icon
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: e => {
                                    if (e.button === Qt.RightButton || trayIcon.modelData.onlyMenu) {
                                        const p = trayIcon.mapToItem(null, 0, trayIcon.height + 14);
                                        trayIcon.modelData.display(bar, p.x, p.y);
                                    } else trayIcon.modelData.activate();
                                }
                            }
                        }
                    }
                }
            }

            // status: input method, wifi, bluetooth, volume, battery
            Pill {
                id: status
                width: statusRow.implicitWidth + 30
                hovered: statusMouse.containsMouse
                highlighted: Panels.open === "control"

                readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
                readonly property var net: wifi?.networks?.values?.find(n => n.connected)
                readonly property var bat: UPower.displayDevice
                readonly property real pct: bat?.percentage ?? 0
                readonly property bool charging: bat?.state === UPowerDeviceState.Charging || bat?.state === UPowerDeviceState.FullyCharged || bat?.state === UPowerDeviceState.PendingCharge
                readonly property int btConnected: Bluetooth.devices.values.filter(d => d.connected).length

                Row {
                    id: statusRow
                    anchors.centerIn: parent
                    spacing: 11

                    Label {
                        visible: Ime.available
                        text: Ime.chinese ? "中" : "EN"
                        color: Ime.chinese ? Theme.lamp : Theme.subtext
                        font.pixelSize: Ime.chinese ? 14 : 11
                        font.weight: Font.ExtraBold
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Icon {
                        icon: !Networking.wifiEnabled ? "wifi_off"
                            : !status.net ? "wifi_find"
                            : status.net.signalStrength > 0.75 ? "signal_wifi_4_bar"
                            : status.net.signalStrength > 0.5 ? "network_wifi_3_bar"
                            : status.net.signalStrength > 0.25 ? "network_wifi_2_bar" : "network_wifi_1_bar"
                        size: 18; fill: 1
                        color: status.net ? Theme.blue : Theme.overlay
                    }
                    Icon {
                        icon: !Bluetooth.defaultAdapter?.enabled ? "bluetooth_disabled" : status.btConnected > 0 ? "bluetooth_connected" : "bluetooth"
                        size: 18
                        color: Bluetooth.defaultAdapter?.enabled ? Theme.blue : Theme.overlay
                    }
                    Icon { icon: Audio.icon; size: 18; fill: 1; color: Audio.muted ? Theme.overlay : Theme.teal }
                    Row {
                        spacing: 3
                        Icon {
                            icon: status.charging ? "battery_charging_full"
                                : status.pct > 0.9 ? "battery_full" : status.pct > 0.75 ? "battery_6_bar"
                                : status.pct > 0.6 ? "battery_5_bar" : status.pct > 0.45 ? "battery_4_bar"
                                : status.pct > 0.3 ? "battery_3_bar" : status.pct > 0.15 ? "battery_2_bar" : "battery_alert"
                            size: 18; fill: 1
                            color: status.charging ? Theme.lamp : status.pct <= 0.15 ? Theme.red : status.pct <= 0.3 ? Theme.mustard : Theme.green
                        }
                        Label { text: Math.round(status.pct * 100) + "%"; font.weight: Font.Bold; color: Theme.text }
                    }
                }
                // unread notifications: a small lamp dot
                Rectangle {
                    visible: Notifs.unread > 0 && Panels.open !== "control"
                    width: 7; height: 7; radius: 4
                    color: Theme.lamp
                    anchors { right: parent.right; rightMargin: 8; top: parent.top; topMargin: 7 }
                }
                MouseArea { id: statusMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Panels.toggle("control") }
            }

            Pill {
                width: 42
                hovered: powerMouse.containsMouse
                Icon { anchors.centerIn: parent; icon: "power_settings_new"; size: 19; color: Theme.red }
                MouseArea { id: powerMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Panels.toggle("power") }
            }
        }
    }
}
