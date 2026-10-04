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
        WlrLayershell.namespace: "whisper-polkit"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: Qt.alpha(Theme.crust, 0.6)

        onVisibleChanged: if (visible) { pw.text = ""; pw.forceActiveFocus(); }

        Rectangle {
            anchors.centerIn: parent
            width: 440
            implicitHeight: col.implicitHeight + 40
            radius: Theme.radius + 8
            color: Theme.glassStrong
            border.width: 1
            border.color: Qt.alpha(Theme.lamp, 0.4)

            ColumnLayout {
                id: col
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
                spacing: 12

                RowLayout {
                    spacing: 12
                    Rectangle {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        radius: 22
                        color: Qt.alpha(Theme.lamp, 0.16)
                        Icon { anchors.centerIn: parent; icon: "shield_lock"; size: 24; fill: 1; color: Theme.lamp }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Label { text: "Authentication needed"; font.pixelSize: 16; font.weight: Font.ExtraBold; color: Theme.lamp }
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
                    background: Rectangle { radius: 14; color: Theme.mantle; border.width: 1; border.color: pw.activeFocus ? Theme.lamp : Theme.surface1 }
                    onAccepted: root.flow?.submit(text)
                    Keys.onEscapePressed: root.flow?.cancelAuthenticationRequest()
                }

                Label {
                    Layout.fillWidth: true
                    visible: (root.flow?.supplementaryMessage ?? "").length > 0 || (root.flow?.failed ?? false)
                    text: root.flow?.supplementaryMessage || "not quite — try again"
                    color: root.flow?.supplementaryIsError || root.flow?.failed ? Theme.red : Theme.subtext
                    font.pixelSize: 12
                }

                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        implicitWidth: 100; implicitHeight: 38; radius: 19
                        color: cancelMouse.containsMouse ? Theme.surface1 : Theme.surface0
                        Label { anchors.centerIn: parent; text: "Cancel" }
                        MouseArea { id: cancelMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.flow?.cancelAuthenticationRequest() }
                    }
                    Rectangle {
                        implicitWidth: 130; implicitHeight: 38; radius: 19
                        color: okMouse.containsMouse ? Qt.lighter(Theme.lamp, 1.08) : Theme.lamp
                        Label { anchors.centerIn: parent; text: "Authenticate"; color: Theme.base; font.weight: Font.ExtraBold }
                        MouseArea { id: okMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.flow?.submit(pw.text) }
                    }
                }
            }
        }
    }
}
