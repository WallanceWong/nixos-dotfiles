import QtQuick
import qs.services

// A HUD plate — the basic surface of the bar: cut corners, a lit edge, and
// accent ticks when highlighted.
HudFrame {
    id: root
    property bool hovered: false
    property bool highlighted: false
    property color tint: "transparent"        // e.g. recording red

    implicitHeight: 34
    cut: 8
    fill: tint.a > 0 ? Qt.alpha(tint, 0.20) : hovered ? Qt.alpha(Theme.surface1, 0.94) : Theme.glass
    stroke: tint.a > 0 ? Qt.alpha(tint, 0.7) : highlighted ? Qt.alpha(Theme.accent, 0.75) : Theme.hairline
    ticks: highlighted || hovered
    tickColor: tint.a > 0 ? tint : Theme.accent
}
