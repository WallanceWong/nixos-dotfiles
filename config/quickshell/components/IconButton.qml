import QtQuick
import qs.services

// Round icon button with a soft hover glow.
Rectangle {
    id: root

    property string icon: ""
    property real iconSize: 20
    property color iconColor: Theme.text
    property bool active: false
    property string tooltip: ""
    signal clicked()
    signal rightClicked()

    implicitWidth: 36
    implicitHeight: 36
    radius: height / 2
    color: active ? Qt.alpha(Theme.lamp, 0.16) : mouse.containsMouse ? Qt.alpha(Theme.surface2, 0.7) : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.fast } }

    Icon {
        anchors.centerIn: parent
        icon: root.icon
        size: root.iconSize
        color: root.active ? Theme.lamp : root.iconColor
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
