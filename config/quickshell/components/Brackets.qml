import QtQuick
import qs.services

// Four corner brackets framing the parent — the targeting-reticle look.
Item {
    id: root
    property color color: Theme.accent
    property real size: 12
    property real weight: 2
    anchors.fill: parent

    Repeater {
        model: 4
        Item {
            required property int index
            readonly property bool atRight: index % 2 === 1
            readonly property bool atBottom: index >= 2
            x: atRight ? root.width - root.size : 0
            y: atBottom ? root.height - root.size : 0
            width: root.size; height: root.size
            Rectangle { width: root.size; height: root.weight; color: root.color; y: parent.atBottom ? root.size - root.weight : 0 }
            Rectangle { width: root.weight; height: root.size; color: root.color; x: parent.atRight ? root.size - root.weight : 0 }
        }
    }
}
