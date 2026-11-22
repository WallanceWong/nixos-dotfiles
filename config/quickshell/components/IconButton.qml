import QtQuick
import qs.services

// Square icon button; hover lights a frame, active fills it in the accent.
Item {
    id: root

    property string icon: ""
    property real iconSize: 20
    property color iconColor: Theme.text
    property bool active: false
    property string tooltip: ""
    // kept for older call sites that set a background colour
    property color color: "transparent"
    signal clicked()
    signal rightClicked()

    implicitWidth: 36
    implicitHeight: 36

    HudFrame {
        anchors.fill: parent
        cut: Math.min(8, root.height / 4)
        fill: root.active ? Qt.alpha(Theme.accent, 0.16) : mouse.containsMouse ? Qt.alpha(Theme.surface2, 0.7) : root.color
        stroke: root.active || mouse.containsMouse ? Qt.alpha(Theme.accent, 0.45) : "transparent"
    }

    Icon {
        anchors.centerIn: parent
        icon: root.icon
        size: root.iconSize
        color: root.active ? Theme.accent : root.iconColor
        fill: root.active ? 1 : 0
        scale: mouse.pressed ? 0.88 : 1
        Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutBack } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: e => e.button === Qt.RightButton ? root.rightClicked() : root.clicked()
    }
}
