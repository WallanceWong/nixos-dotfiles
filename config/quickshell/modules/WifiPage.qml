import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Networking
import qs.services
import qs.components

// Wi-Fi network list. Known/open networks connect on click; new secured
// ones ask for the password inline.
ColumnLayout {
    id: root
    property bool active: false
    spacing: 6

    readonly property var dev: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
    readonly property var nets: (dev?.networks?.values ?? []).slice().sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
    property var asking: null

    onActiveChanged: { if (dev) dev.scannerEnabled = active; if (!active) asking = null; }

    Label {
        visible: !Networking.wifiEnabled
        text: "Wi-Fi is off"
        color: Theme.overlay
    }

    Repeater {
        model: Networking.wifiEnabled ? root.nets : []
        ColumnLayout {
            id: row
            required property var modelData
            readonly property var n: modelData
            Layout.fillWidth: true
            spacing: 4

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 46
                radius: Theme.radiusSmall + 2
                color: row.n.connected ? Qt.alpha(Theme.lamp, 0.13) : netMouse.containsMouse ? Theme.surface1 : Theme.surface0
                border.width: 1
                border.color: row.n.connected ? Qt.alpha(Theme.lamp, 0.35) : Theme.hairline
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10
                    Icon {
                        icon: row.n.signalStrength > 0.75 ? "signal_wifi_4_bar" : row.n.signalStrength > 0.5 ? "network_wifi_3_bar" : row.n.signalStrength > 0.25 ? "network_wifi_2_bar" : "network_wifi_1_bar"
                        size: 19; fill: 1
                        color: row.n.connected ? Theme.lamp : Theme.blue
                    }
                    Label { Layout.fillWidth: true; text: row.n.name; color: row.n.connected ? Theme.lamp : Theme.text }
                    Icon { visible: row.n.security !== WifiSecurityType.Open; icon: "lock"; size: 15; color: Theme.overlay }
                    Label {
                        text: row.n.stateChanging ? "…" : row.n.connected ? "connected" : row.n.known ? "saved" : ""
                        font.pixelSize: 11
                        color: Theme.subtext
                    }
                }
                MouseArea {
                    id: netMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (row.n.connected) row.n.disconnect();
                        else if (row.n.known || row.n.security === WifiSecurityType.Open) row.n.connect();
                        else root.asking = (root.asking === row.n ? null : row.n);
                    }
                }
            }

            // inline password
            RowLayout {
                Layout.fillWidth: true
                visible: root.asking === row.n
                spacing: 6
                TextField {
                    id: pw
                    Layout.fillWidth: true
                    placeholderText: "password for " + row.n.name
                    echoMode: TextInput.Password
                    color: Theme.text
                    placeholderTextColor: Theme.overlay
                    font.family: Theme.font
                    font.pixelSize: 13
                    background: Rectangle { radius: 12; color: Theme.mantle; border.width: 1; border.color: pw.activeFocus ? Theme.lamp : Theme.surface1 }
                    onVisibleChanged: if (visible) { text = ""; forceActiveFocus(); }
                    onAccepted: { row.n.connectWithPsk(text); root.asking = null; }
                }
                IconButton { icon: "arrow_forward"; onClicked: { row.n.connectWithPsk(pw.text); root.asking = null; } }
            }
        }
    }
}
