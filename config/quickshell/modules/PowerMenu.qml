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
    WlrLayershell.namespace: "eva-power"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    property int selected: 0
    onOpenChanged: if (open) { selected = 0; keys.forceActiveFocus(); }

    readonly property var actions: [
        { icon: "hexagon", name: "AT FIELD", real: "LOCK", key: "l", fn: () => Locker.lock() },
        { icon: "bedtime", name: "STANDBY", real: "SLEEP", key: "s", cmd: ["systemctl", "suspend"] },
        { icon: "eject", name: "EJECT PLUG", real: "LOG OUT", key: "e", cmd: ["hyprctl", "dispatch", "exit"] },
        { icon: "restart_alt", name: "REACTIVATE", real: "RESTART", key: "r", cmd: ["systemctl", "reboot"] },
        { icon: "power_settings_new", name: Theme.magi ? "SELF-DESTRUCT" : "SHUTDOWN", real: "POWER OFF", key: "p", cmd: ["systemctl", "poweroff"] }
    ]
    function run(i) {
        const a = actions[i];
        Panels.close();
        if (a.fn) a.fn(); else Quickshell.execDetached(a.cmd);
    }

    Rectangle {
        id: veil
        anchors.fill: parent
        color: Qt.alpha(Theme.crust, 0.72)
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

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4
            Caps {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Theme.magi ? "NERV HQ · SYSTEM CONTROL" : "EVA-01 · PILOT " + (Quickshell.env("USER") ?? "")
                color: Theme.accent
                font.pixelSize: 15
                font.weight: Font.Bold
                font.letterSpacing: 5
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Theme.magi ? "作戦終了" : "活動限界"
                color: Theme.text
                font.family: Theme.title
                font.weight: Font.Black
                font.pixelSize: 54
            }
        }

        Row {
            spacing: 18
            Repeater {
                model: panel.actions
                Item {
                    id: btn
                    required property var modelData
                    required property int index
                    readonly property bool sel: panel.selected === index
                    readonly property color accent: index === 4 ? Theme.alert : Theme.accent
                    width: 168
                    height: 190
                    scale: sel ? 1.04 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutBack } }

                    HudFrame {
                        anchors.fill: parent
                        cut: 18
                        fill: btn.sel ? Qt.alpha(btn.accent, 0.14) : Theme.glassStrong
                        stroke: btn.sel ? btn.accent : Theme.hairline
                        strokeWidth: btn.sel ? 2 : 1
                        ticks: btn.sel
                        tickColor: btn.accent
                    }
                    Hazard {
                        visible: btn.index === 4 && btn.sel
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 4; leftMargin: 22 }
                        height: 6
                        color: Theme.alert
                        stripe: 6
                        running: Theme.drama
                    }
                    Text {
                        anchors { right: parent.right; rightMargin: 12; top: parent.top; topMargin: 8 }
                        text: "[" + btn.modelData.key.toUpperCase() + "]"
                        color: btn.sel ? btn.accent : Theme.overlay
                        font.family: Theme.mono
                        font.pixelSize: 11
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 10
                        Icon { anchors.horizontalCenter: parent.horizontalCenter; icon: btn.modelData.icon; size: 50; fill: btn.sel ? 1 : 0; color: btn.sel ? btn.accent : Theme.text }
                        Caps { anchors.horizontalCenter: parent.horizontalCenter; text: btn.modelData.name; font.pixelSize: 17; font.weight: Font.Bold; font.letterSpacing: 2; color: btn.sel ? btn.accent : Theme.text }
                        Caps { anchors.horizontalCenter: parent.horizontalCenter; text: btn.modelData.real; font.pixelSize: 11; color: Theme.subtext }
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

        Caps {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "← → SELECT   ·   ENTER CONFIRM   ·   ESC CANCEL"
            color: Theme.subtext
            font.pixelSize: 12
        }
    }
}
