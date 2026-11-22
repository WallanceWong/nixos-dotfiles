import QtQuick
import QtQuick.Shapes
import qs.services

// The basic HUD surface: a panel with two corners cut at 45° (top-left and
// bottom-right, like the NERV displays), a thin lit edge, and optional
// tick marks on the cut corners.
Shape {
    id: root

    property color fill: Theme.glass
    property color stroke: Theme.hairline
    property real strokeWidth: 1
    property real cut: Theme.chamfer          // size of the cut corners
    property bool cutTopLeft: true
    property bool cutTopRight: false
    property bool cutBottomRight: true
    property bool cutBottomLeft: false
    property bool ticks: false                // little accent strokes along the cuts
    property color tickColor: Theme.accent

    readonly property real c: Math.min(cut, width / 2, height / 2)
    readonly property real h: strokeWidth / 2

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.fill
        strokeColor: root.stroke
        strokeWidth: root.strokeWidth
        joinStyle: ShapePath.MiterJoin
        startX: root.h + (root.cutTopLeft ? root.c : 0); startY: root.h
        PathLine { x: root.width - root.h - (root.cutTopRight ? root.c : 0); y: root.h }
        PathLine { x: root.width - root.h; y: root.h + (root.cutTopRight ? root.c : 0) }
        PathLine { x: root.width - root.h; y: root.height - root.h - (root.cutBottomRight ? root.c : 0) }
        PathLine { x: root.width - root.h - (root.cutBottomRight ? root.c : 0); y: root.height - root.h }
        PathLine { x: root.h + (root.cutBottomLeft ? root.c : 0); y: root.height - root.h }
        PathLine { x: root.h; y: root.height - root.h - (root.cutBottomLeft ? root.c : 0) }
        PathLine { x: root.h; y: root.h + (root.cutTopLeft ? root.c : 0) }
        PathLine { x: root.h + (root.cutTopLeft ? root.c : 0); y: root.h }
    }

    // accent ticks: a heavier stroke over each cut corner
    ShapePath {
        fillColor: "transparent"
        strokeColor: root.ticks ? root.tickColor : "transparent"
        strokeWidth: 2
        capStyle: ShapePath.FlatCap
        startX: root.cutTopLeft ? 1 : 0; startY: root.cutTopLeft ? root.c + 1 : 0
        PathLine { x: root.cutTopLeft ? root.c + 1 : 0; y: root.cutTopLeft ? 1 : 0 }
        PathMove { x: root.cutBottomRight ? root.width - root.c - 1 : root.width; y: root.cutBottomRight ? root.height - 1 : root.height }
        PathLine { x: root.cutBottomRight ? root.width - 1 : root.width; y: root.cutBottomRight ? root.height - root.c - 1 : root.height }
    }

    Behavior on fill { ColorAnimation { duration: Theme.fast } }
    Behavior on stroke { ColorAnimation { duration: Theme.normal } }
}
