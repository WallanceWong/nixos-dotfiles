import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.services
import qs.components

// Bluetooth devices: connected and known first, then anything found by scanning.
ColumnLayout {
    id: root
    property bool active: false
    spacing: 6

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: Bluetooth.devices.values.slice()
        .filter(d => d.paired || d.connected || (root.adapter?.discovering && d.name.length > 0))
        .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))

    onActiveChanged: if (!active && adapter?.discovering) adapter.discovering = false

    RowLayout {
        Layout.fillWidth: true
        Label { Layout.fillWidth: true; text: root.adapter?.enabled ? (root.adapter.discovering ? "looking for devices…" : "known devices") : "Bluetooth is off"; color: Theme.subtext; font.pixelSize: 12 }
        IconButton {
            visible: !!root.adapter?.enabled
            icon: root.adapter?.discovering ? "stop" : "radar"
            active: !!root.adapter?.discovering
            onClicked: root.adapter.discovering = !root.adapter.discovering
        }
    }

    Repeater {
        model: root.adapter?.enabled ? root.devices : []
        Rectangle {
            id: dev
            required property var modelData
            readonly property var d: modelData
            Layout.fillWidth: true
            implicitHeight: 50
            radius: Theme.radiusSmall + 2
            color: d.connected ? Qt.alpha(Theme.lamp, 0.13) : devMouse.containsMouse ? Theme.surface1 : Theme.surface0
            border.width: 1
            border.color: d.connected ? Qt.alpha(Theme.lamp, 0.35) : Theme.hairline
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10
                Icon {
                    icon: dev.d.icon.includes("mouse") ? "mouse" : dev.d.icon.includes("keyboard") ? "keyboard"
                        : dev.d.icon.includes("headset") || dev.d.icon.includes("headphone") || dev.d.icon.includes("audio") ? "headphones"
                        : dev.d.icon.includes("phone") ? "smartphone" : dev.d.icon.includes("game") ? "sports_esports" : "bluetooth"
                    size: 19
                    color: dev.d.connected ? Theme.lamp : Theme.blue
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Label { Layout.fillWidth: true; text: dev.d.name; color: dev.d.connected ? Theme.lamp : Theme.text }
                    Label {
                        text: dev.d.state === BluetoothDeviceState.Connecting ? "connecting…" : dev.d.pairing ? "pairing…"
                            : dev.d.connected ? ("connected" + (dev.d.batteryAvailable ? " · " + Math.round(dev.d.battery * 100) + "%" : ""))
                            : dev.d.paired ? "paired" : "tap to pair"
                        font.pixelSize: 11
                        color: Theme.subtext
                    }
                }
                IconButton {
                    visible: dev.d.paired && !dev.d.connected
                    icon: "delete"
                    iconSize: 17
                    onClicked: dev.d.forget()
                }
            }
            MouseArea {
                id: devMouse
                anchors.fill: parent
                anchors.rightMargin: dev.d.paired && !dev.d.connected ? 44 : 0
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (dev.d.connected) dev.d.disconnect();
                    else if (dev.d.paired) dev.d.connect();
                    else { dev.d.trusted = true; dev.d.pair(); }
                }
            }
        }
    }
}
