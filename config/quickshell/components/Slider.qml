import QtQuick
import qs.services

// Sync-ratio style slider: an icon block on the left (click to mute), a
// segmented bar that lights up in the accent, a readout on the right.
Item {
    id: root

    property real value: 0            // 0..1, bound from outside
    property string icon: ""
    property color accent: Theme.accent
    property bool dimmed: false
    signal moved(real value)
    signal iconClicked()

    implicitHeight: 40
    implicitWidth: 300

    readonly property real shown: drag.pressed ? drag.live : value
    readonly property int segments: 32

    HudFrame {
        id: track
        anchors.fill: parent
        cut: 9
        fill: Qt.alpha(Theme.surface0, 0.9)
        stroke: Theme.hairline
    }

    // icon block
    Rectangle {
        id: iconBlock
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 4; leftMargin: 4 }
        width: 34
        color: root.dimmed ? Theme.surface2 : root.accent
        Icon {
            anchors.centerIn: parent
            icon: root.icon
            size: 18
            fill: 1
            color: root.dimmed ? Theme.subtext : Theme.crust
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.iconClicked() }
    }

    // segments
    Row {
        id: bar
        anchors { left: iconBlock.right; leftMargin: 8; right: readout.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
        height: 16
        spacing: 2
        Repeater {
            model: root.segments
            Rectangle {
                required property int index
                readonly property bool lit: (index + 0.5) / root.segments <= root.shown
                width: (bar.width - (root.segments - 1) * bar.spacing) / root.segments
                height: bar.height
                color: lit ? (root.dimmed ? Theme.overlay : root.accent) : Qt.alpha(Theme.overlay, 0.28)
                Behavior on color { ColorAnimation { duration: Theme.fast } }
            }
        }
    }

    Text {
        id: readout
        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        width: 38
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.shown * 100) + "%"
        color: root.dimmed ? Theme.subtext : root.accent
        font.family: Theme.mono
        font.pixelSize: 12
        font.weight: Font.Bold
    }

    MouseArea {
        id: drag
        property real live: 0
        anchors { fill: bar; topMargin: -10; bottomMargin: -10 }
        cursorShape: Qt.PointingHandCursor
        function at(x) { return Math.max(0, Math.min(1, x / bar.width)); }
        onPressed: e => { live = at(e.x); root.moved(live); }
        onPositionChanged: e => { if (pressed) { live = at(e.x); root.moved(live); } }
        onWheel: e => root.moved(Math.max(0, Math.min(1, root.value + (e.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
