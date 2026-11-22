import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray
import Quickshell.Bluetooth
import Quickshell.Networking
import qs.services
import qs.components

// The bar: a strip of HUD plates. Left: unit badge, workspaces as hex cells,
// window title. Centre: segment clock. Right: recording, music, tray, status
// and the power readout (external / internal power, Eva-style).
Variants {
    // EVA_ONLY limits the shell to one screen (used for testing)
    model: Quickshell.screens.filter(s => !Quickshell.env("EVA_ONLY") || s.name === Quickshell.env("EVA_ONLY"))

    PanelWindow {
        id: bar
        required property var modelData
        screen: modelData

        WlrLayershell.namespace: "eva-bar"
        WlrLayershell.layer: WlrLayer.Top
        anchors { top: true; left: true; right: true }
        implicitHeight: 52
        exclusiveZone: 46
        color: "transparent"

        readonly property var monitor: Hyprland.monitorFor(modelData)
        // low battery while unplugged: the bar raises the alarm
        readonly property bool lowPower: Stats.onBattery && Stats.battery <= 0.15

        // emergency strip along the very top (NERV HQ: always when low, Unit-01: just a line)
        Hazard {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: Theme.drama ? 4 : 2
            visible: bar.lowPower
            color: Theme.alert
            stripe: 8
            running: Theme.drama
        }

        // ── left: unit badge, workspaces, window title ──
        Row {
            anchors { left: parent.left; leftMargin: 12; top: parent.top; topMargin: 8 }
            spacing: 6

            // unit badge: NERV leaf + setup name — opens the launcher
            Pill {
                id: badge
                width: badgeRow.implicitWidth + 24
                hovered: badgeMouse.containsMouse
                highlighted: Panels.open === "launcher"
                Row {
                    id: badgeRow
                    anchors.centerIn: parent
                    spacing: 8
                    Image {
                        id: leaf
                        anchors.verticalCenter: parent.verticalCenter
                        source: "../assets/eva/nerv.svg"
                        sourceSize.height: 22
                        height: 22
                        fillMode: Image.PreserveAspectFit
                        visible: false
                    }
                    MultiEffect {
                        anchors.verticalCenter: parent.verticalCenter
                        width: leaf.width; height: leaf.height
                        source: leaf
                        colorization: 1
                        colorizationColor: Theme.magi ? Theme.alert : Theme.accent
                    }
                    Caps {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Theme.name
                        color: Theme.text
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        font.letterSpacing: 2
                    }
                }
                MouseArea { id: badgeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Panels.launcher("apps") }
            }

            // workspaces: hex cells 01..05
            Pill {
                width: cells.implicitWidth + 18
                Row {
                    id: cells
                    anchors.centerIn: parent
                    spacing: 3
                    Repeater {
                        model: 5
                        Item {
                            id: cell
                            required property int index
                            readonly property int wsId: index + 1
                            readonly property var ws: Hyprland.workspaces.values.find(w => w.id === wsId)
                            readonly property bool active: bar.monitor?.activeWorkspace?.id === wsId
                            readonly property bool occupied: (ws?.toplevels?.values?.length ?? 0) > 0
                            readonly property color tone: ws?.urgent ? Theme.alert : active ? Theme.accent : wsMouse.containsMouse ? Theme.armour : occupied ? Theme.subtext : Theme.overlay
                            width: 30; height: 26
                            Hexagon {
                                anchors.centerIn: parent
                                implicitWidth: 28
                                fill: cell.active ? cell.tone : cell.occupied ? Qt.alpha(cell.tone, 0.16) : "transparent"
                                stroke: cell.tone
                                strokeWidth: 1.2
                            }
                            Text {
                                anchors.centerIn: parent
                                text: "0" + cell.wsId
                                color: cell.active ? Theme.crust : cell.tone
                                font.family: Theme.hud
                                font.pixelSize: 12
                                font.weight: Font.Bold
                            }
                            MouseArea {
                                id: wsMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Hyprland.dispatch("workspace " + cell.wsId)
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
                Caps {
                    id: titleText
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    text: parent.title.length ? parent.title : (Theme.magi ? "ALL SYSTEMS NOMINAL" : "STANDBY")
                    color: parent.title.length ? Theme.subtext : Theme.overlay
                    font.pixelSize: 12
                    font.letterSpacing: 1.2
                }
            }
        }

        // ── centre: segment clock ──
        Pill {
            id: clockPill
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 8 }
            width: clockRow.implicitWidth + 30
            hovered: clockMouse.containsMouse
            highlighted: Panels.open === "dashboard"
            cutTopRight: true
            cutBottomLeft: true
            SystemClock { id: clock; precision: SystemClock.Minutes }
            Row {
                id: clockRow
                anchors.centerIn: parent
                spacing: 10
                SevenSeg {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatTime(clock.date, "HH:mm")
                    digitHeight: 18
                    color: Theme.accent
                    dim: 0.08
                }
                Rectangle { width: 1; height: 16; color: Theme.hairline; anchors.verticalCenter: parent.verticalCenter }
                Caps {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDate(clock.date, "ddd dd MMM")
                    color: Theme.subtext
                    font.pixelSize: 12
                }
            }
            MouseArea { id: clockMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Panels.toggle("dashboard") }
        }

        // ── right ──
        Row {
            anchors { right: parent.right; rightMargin: 12; top: parent.top; topMargin: 8 }
            spacing: 6

            // recording indicator
            Pill {
                id: recPill
                visible: Recorder.recording
                width: recRow.implicitWidth + 26
                tint: Theme.alert
                property int secs: 0
                Timer { running: Recorder.recording; interval: 1000; repeat: true; triggeredOnStart: true; onTriggered: recPill.secs = Math.floor((Date.now() - Recorder.startedAt) / 1000) }
                Row {
                    id: recRow
                    anchors.centerIn: parent
                    spacing: 7
                    Rectangle {
                        width: 8; height: 8; color: Theme.alert
                        anchors.verticalCenter: parent.verticalCenter
                        SequentialAnimation on opacity { running: Recorder.recording; loops: Animation.Infinite; NumberAnimation { to: 0.2; duration: 500 } NumberAnimation { to: 1; duration: 500 } }
                    }
                    Caps { text: "REC " + Math.floor(recPill.secs / 60) + ":" + String(recPill.secs % 60).padStart(2, "0"); color: Theme.alert; font.pixelSize: 12; font.weight: Font.Bold }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Recorder.toggle(false) }
            }

            // now playing — Shinji's tape player (Unit-01) / a signal trace (NERV HQ)
            Pill {
                id: media
                readonly property var players: Mpris.players.values.filter(p => !p.dbusName.includes("playerctld"))
                readonly property var player: players.find(p => p.isPlaying) ?? players[0]
                readonly property bool playing: !!player?.isPlaying
                visible: !!player && (player.trackTitle ?? "").length > 0
                width: mediaRow.implicitWidth + 24
                hovered: mediaMouse.containsMouse
                Row {
                    id: mediaRow
                    anchors.centerIn: parent
                    spacing: 8

                    // two cassette reels, turning while it plays
                    Row {
                        visible: !Theme.magi
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Repeater {
                            model: 2
                            Item {
                                width: 13; height: 13
                                Rectangle { anchors.fill: parent; radius: width / 2; color: "transparent"; border.color: Theme.armour; border.width: 1.5 }
                                Item {
                                    anchors.fill: parent
                                    RotationAnimation on rotation { running: media.playing && media.visible; from: 0; to: 360; duration: 2400; loops: Animation.Infinite }
                                    Repeater {
                                        model: 3
                                        Rectangle { required property int index; width: 1.5; height: 5; color: Theme.armour; x: 5.75; y: 1.5; transformOrigin: Item.Bottom; rotation: index * 120 }
                                    }
                                }
                            }
                        }
                    }
                    // signal bars (NERV HQ)
                    Row {
                        visible: Theme.magi
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Repeater {
                            model: 5
                            Rectangle {
                                required property int index
                                width: 3
                                anchors.verticalCenter: parent.verticalCenter
                                color: Theme.signal
                                height: 4
                                SequentialAnimation on height {
                                    running: media.playing && media.visible && Theme.magi
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 6 + (index * 7) % 10; duration: 180 + index * 40 }
                                    NumberAnimation { to: 3 + (index * 3) % 5; duration: 220 + index * 30 }
                                }
                            }
                        }
                    }
                    Caps {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Theme.magi ? "AUDIO" : (media.playing ? "▶ PLAY" : "■ STOP")
                        color: Theme.overlay
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: (media.player?.trackTitle ?? "") + ((media.player?.trackArtist ?? "").length ? "  ·  " + media.player.trackArtist : "")
                        width: Math.min(implicitWidth, 240)
                        color: Theme.magi ? Theme.signal : Theme.armour
                        font.pixelSize: 13
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
                            implicitSize: 17
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

            // status: input method, wifi, bluetooth, volume
            Pill {
                id: status
                width: statusRow.implicitWidth + 26
                hovered: statusMouse.containsMouse
                highlighted: Panels.open === "control"

                readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
                readonly property var net: wifi?.networks?.values?.find(n => n.connected)
                readonly property int btConnected: Bluetooth.devices.values.filter(d => d.connected).length

                Row {
                    id: statusRow
                    anchors.centerIn: parent
                    spacing: 11

                    Caps {
                        visible: Ime.available
                        text: Ime.chinese ? "中" : "EN"
                        color: Ime.chinese ? Theme.accent : Theme.subtext
                        font.family: Ime.chinese ? Theme.title : Theme.hud
                        font.pixelSize: Ime.chinese ? 14 : 12
                        font.weight: Font.Bold
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Icon {
                        icon: !Networking.wifiEnabled ? "wifi_off"
                            : !status.net ? "wifi_find"
                            : status.net.signalStrength > 0.75 ? "signal_wifi_4_bar"
                            : status.net.signalStrength > 0.5 ? "network_wifi_3_bar"
                            : status.net.signalStrength > 0.25 ? "network_wifi_2_bar" : "network_wifi_1_bar"
                        size: 18; fill: 1
                        color: status.net ? Theme.info : Theme.overlay
                    }
                    Icon {
                        icon: !Bluetooth.defaultAdapter?.enabled ? "bluetooth_disabled" : status.btConnected > 0 ? "bluetooth_connected" : "bluetooth"
                        size: 18
                        color: Bluetooth.defaultAdapter?.enabled ? Theme.info : Theme.overlay
                    }
                    Icon { icon: Audio.icon; size: 18; fill: 1; color: Audio.muted ? Theme.overlay : Theme.armour }
                }
                // unread notifications: a small lit square
                Rectangle {
                    visible: Notifs.unread > 0 && Panels.open !== "control"
                    width: 6; height: 6
                    color: Theme.accent
                    anchors { right: parent.right; rightMargin: 6; top: parent.top; topMargin: 6 }
                }
                MouseArea { id: statusMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Panels.toggle("control") }
            }

            // power: EXTERNAL (umbilical connected) / INTERNAL + countdown
            Pill {
                id: power
                width: powerRow.implicitWidth + 24
                hovered: powerMouse.containsMouse
                highlighted: Panels.open === "control"
                tint: bar.lowPower ? Theme.alert : "transparent"
                StatsUser { active: Stats.onBattery }
                readonly property color tone: bar.lowPower ? Theme.alert : Stats.onBattery ? (Stats.battery <= 0.3 ? Theme.caution : Theme.accent) : Theme.signal
                Row {
                    id: powerRow
                    anchors.centerIn: parent
                    spacing: 8
                    // battery as 5 cells
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Repeater {
                            model: 5
                            Rectangle {
                                required property int index
                                width: 4; height: 12
                                color: (index + 0.5) / 5 <= Stats.battery ? power.tone : Qt.alpha(Theme.overlay, 0.35)
                            }
                        }
                    }
                    Caps {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Stats.onBattery ? "INT" : "EXT"
                        color: power.tone
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }
                    SevenSeg {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Stats.onBattery && Stats.countdown > 0
                        text: Stats.clock(Stats.countdown).slice(0, 5)
                        digitHeight: 14
                        color: power.tone
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round(Stats.battery * 100) + "%"
                        color: Theme.text
                        font.family: Theme.mono
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }
                }
                SequentialAnimation on opacity {
                    running: bar.lowPower && Theme.drama
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.45; duration: 420 }
                    NumberAnimation { to: 1; duration: 420 }
                    onStopped: power.opacity = 1
                }
                MouseArea { id: powerMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Panels.toggle("control") }
            }

            Pill {
                width: 38
                hovered: offMouse.containsMouse
                Icon { anchors.centerIn: parent; icon: "power_settings_new"; size: 19; color: Theme.alert }
                MouseArea { id: offMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Panels.toggle("power") }
            }
        }
    }
}
