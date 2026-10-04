import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// Where to go when the night is over.
PanelWindow {
    id: panel

    readonly property bool open: Panels.open === "power"
    screen: Panels.screen
    visible: open || veil.opacity > 0
    WlrLayershell.namespace: "whisper-power"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    property int selected: 0
    onOpenChanged: if (open) { selected = 0; keys.forceActiveFocus(); }

    readonly property var actions: [
        { icon: "lock", name: "Lock", key: "l", fn: () => Locker.lock() },
        { icon: "bedtime", name: "Sleep", key: "s", cmd: ["systemctl", "suspend"] },
        { icon: "logout", name: "Log out", key: "e", cmd: ["hyprctl", "dispatch", "exit"] },
        { icon: "restart_alt", name: "Restart", key: "r", cmd: ["systemctl", "reboot"] },
        { icon: "power_settings_new", name: "Shut down", key: "p", cmd: ["systemctl", "poweroff"] }
    ]
    function run(i) {
        const a = actions[i];
        Panels.close();
        if (a.fn) a.fn(); else Quickshell.execDetached(a.cmd);
    }

    Rectangle {
        id: veil
        anchors.fill: parent
        color: Qt.alpha(Theme.crust, 0.62)
        opacity: panel.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.normal; easing.type: Theme.easing } }
        MouseArea { anchors.fill: parent; onClicked: Panels.close() }
    }

    Item {
        id: keys
        focus: panel.open
        Keys.onEscapePressed: Panels.close()
        Keys.onLeftPressed: panel.selected = (panel.selected + 4) % 5
        Keys.onRightPressed: panel.selected = (panel.selected + 1) % 5
        Keys.onReturnPressed: panel.run(panel.selected)
        Keys.onEnterPressed: panel.run(panel.selected)
        Keys.onPressed: e => {
            const i = panel.actions.findIndex(a => a.key === e.text);
            if (i >= 0) panel.run(i);
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 28
        opacity: veil.opacity
        scale: 0.94 + 0.06 * veil.opacity

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "good night, " + Quickshell.env("USER")
            font.pixelSize: 26
            font.weight: Font.ExtraBold
            color: Theme.lamp
        }

        Row {
            spacing: 18
            Repeater {
                model: panel.actions
                Rectangle {
                    id: btn
                    required property var modelData
                    required property int index
                    readonly property bool sel: panel.selected === index
                    readonly property color accent: index === 4 ? Theme.red : Theme.lamp
                    width: 150
                    height: 170
                    radius: Theme.radius + 8
                    color: sel ? Theme.surface1 : Theme.glassStrong
                    border.width: sel ? 2 : 1
                    border.color: sel ? accent : Theme.hairline
                    scale: sel ? 1.04 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutBack } }
                    Behavior on color { ColorAnimation { duration: Theme.fast } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 14
                        Icon { anchors.horizontalCenter: parent.horizontalCenter; icon: btn.modelData.icon; size: 46; fill: btn.sel ? 1 : 0; color: btn.sel ? btn.accent : Theme.text }
                        Label { anchors.horizontalCenter: parent.horizontalCenter; text: btn.modelData.name; font.pixelSize: 15; font.weight: Font.Bold; color: btn.sel ? btn.accent : Theme.text }
                        Label { anchors.horizontalCenter: parent.horizontalCenter; text: btn.modelData.key.toUpperCase(); font.pixelSize: 11; color: Theme.overlay }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: panel.selected = btn.index
                        onClicked: panel.run(btn.index)
                    }
                }
            }
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Esc to stay up a little longer"
            color: Theme.subtext
            font.pixelSize: 12
        }
    }
}
