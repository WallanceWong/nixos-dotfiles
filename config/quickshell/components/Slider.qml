import QtQuick
import qs.services

// Rounded slider: icon on the left (click it to mute), lamp-lit fill.
Item {
    id: root

    property real value: 0            // 0..1, bound from outside
    property string icon: ""
    property color accent: Theme.lamp
    property bool dimmed: false
    signal moved(real value)
    signal iconClicked()

    implicitHeight: 42
    implicitWidth: 300

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.surface0
        border.width: 1
        border.color: Theme.hairline

        Rectangle {
            id: fillBar
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: Math.max(height, parent.width * (drag.pressed ? drag.live : root.value))
            radius: height / 2
            color: root.dimmed ? Theme.surface2 : Qt.alpha(root.accent, 0.85)
            Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: Theme.normal; easing.type: Theme.easing } }
            Behavior on color { ColorAnimation { duration: Theme.normal } }
        }

        Text {
            anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
            text: Math.round((drag.pressed ? drag.live : root.value) * 100) + "%"
            color: Theme.subtext
            font.family: Theme.font
            font.pixelSize: 12
            font.weight: Font.Bold
        }
    }

    MouseArea {
        id: drag
        property real live: 0
        anchors.fill: parent
        anchors.leftMargin: 44
        cursorShape: Qt.PointingHandCursor
        function at(x) { return Math.max(0, Math.min(1, (x + 44) / track.width)); }
        onPressed: e => { live = at(e.x); root.moved(live); }
        onPositionChanged: e => { if (pressed) { live = at(e.x); root.moved(live); } }
        onWheel: e => root.moved(Math.max(0, Math.min(1, root.value + (e.angleDelta.y > 0 ? 0.05 : -0.05))))
    }

    Item {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: 44
        Icon {
            anchors.centerIn: parent
            icon: root.icon
            size: 19
            fill: 1
            color: root.dimmed ? Theme.subtext : Theme.base
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.iconClicked()
        }
    }
}
