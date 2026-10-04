import QtQuick
import qs.services

// A softly lit glass pill — the basic surface of the bar.
Rectangle {
    id: root
    property bool hovered: false
    property bool highlighted: false

    implicitHeight: 38
    radius: height / 2
    color: hovered ? Qt.alpha(Theme.surface1, 0.92) : Theme.glass
    border.width: 1
    border.color: highlighted ? Qt.alpha(Theme.lamp, 0.45) : Theme.hairline

    Behavior on color { ColorAnimation { duration: Theme.fast } }
    Behavior on border.color { ColorAnimation { duration: Theme.normal } }
}
