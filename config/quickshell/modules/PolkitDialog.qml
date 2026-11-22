import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit
import qs.services
import qs.components

// Password prompt when an app asks for admin rights (polkit agent).
Scope {
    id: root

    PolkitAgent { id: agent }
    readonly property var flow: agent.flow
    readonly property bool open: agent.isActive && !!flow

    PanelWindow {
        id: panel
        screen: Panels.screen
        visible: root.open
        WlrLayershell.namespace: "eva-polkit"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: Qt.alpha(Theme.crust, 0.6)

        onVisibleChanged: if (visible) { pw.text = ""; pw.forceActiveFocus(); }

        Item {
            anchors.centerIn: parent
            width: 460
            implicitHeight: col.implicitHeight + 40
            height: implicitHeight
            HudFrame {
                anchors.fill: parent
                fill: Theme.glassStrong
                stroke: Theme.caution
                strokeWidth: 1.5
                cut: 18
                ticks: true
                tickColor: Theme.caution
            }
            Hazard { anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 22; rightMargin: 4; topMargin: 2 } height: 6; color: Theme.caution; stripe: 7 }

            ColumnLayout {
                id: col
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
                spacing: 12

                RowLayout {
                    spacing: 12
                    Rectangle {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        radius: 0
                        color: Qt.alpha(Theme.caution, 0.16)
                        border.width: 1
                        border.color: Theme.caution
                        Icon { anchors.centerIn: parent; icon: "shield_lock"; size: 24; fill: 1; color: Theme.caution }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Caps { text: "CLEARANCE REQUIRED · 権限"; font.pixelSize: 16; font.weight: Font.Bold; font.letterSpacing: 2.5; color: Theme.caution }
                        Label { Layout.fillWidth: true; text: root.flow?.message ?? ""; wrapMode: Text.Wrap; maximumLineCount: 3; color: Theme.subtext; font.weight: Font.Medium }
                    }
                }

                TextField {
                    id: pw
                    Layout.fillWidth: true
                    placeholderText: root.flow?.inputPrompt?.replace(/:\s*$/, "") || "password"
                    echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                    color: Theme.text
                    placeholderTextColor: Theme.overlay
                    font.family: Theme.font
                    font.pixelSize: 15
                    padding: 12
                    background: Rectangle { radius: 0; color: Theme.mantle; border.width: 1; border.color: pw.activeFocus ? Theme.accent : Theme.surface1 }
                    onAccepted: root.flow?.submit(text)
                    Keys.onEscapePressed: root.flow?.cancelAuthenticationRequest()
                }

                Label {
                    Layout.fillWidth: true
                    visible: (root.flow?.supplementaryMessage ?? "").length > 0 || (root.flow?.failed ?? false)
                    text: root.flow?.supplementaryMessage || "ACCESS DENIED — TRY AGAIN"
                    color: root.flow?.supplementaryIsError || root.flow?.failed ? Theme.alert : Theme.subtext
                    font.pixelSize: 12
                }

                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        implicitWidth: 100; implicitHeight: 38; radius: 0
                        color: cancelMouse.containsMouse ? Theme.surface1 : Theme.surface0
                        border.width: 1
                        border.color: Theme.hairline
                        Caps { anchors.centerIn: parent; text: "CANCEL"; color: Theme.text; font.pixelSize: 13; font.weight: Font.Bold }
                        MouseArea { id: cancelMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.flow?.cancelAuthenticationRequest() }
                    }
                    Rectangle {
                        implicitWidth: 130; implicitHeight: 38; radius: 0
                        color: okMouse.containsMouse ? Qt.lighter(Theme.accent, 1.08) : Theme.accent
                        Caps { anchors.centerIn: parent; text: "AUTHORIZE"; color: Theme.crust; font.pixelSize: 13; font.weight: Font.Bold; font.letterSpacing: 2 }
                        MouseArea { id: okMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.flow?.submit(pw.text) }
                    }
                }
            }
        }
    }
}
