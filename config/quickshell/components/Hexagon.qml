import QtQuick
import QtQuick.Shapes
import qs.services

// A flat-topped hexagon (AT field cells, workspace markers, MAGI nodes).
Shape {
    id: root
    property color fill: "transparent"
    property color stroke: Theme.accent
    property real strokeWidth: 1.5
    // flat top: width is corner to corner, height = width * √3/2
    implicitWidth: 28
    implicitHeight: implicitWidth * 0.866
    preferredRendererType: Shape.CurveRenderer

    readonly property real s: strokeWidth / 2
    ShapePath {
        fillColor: root.fill
        strokeColor: root.stroke
        strokeWidth: root.strokeWidth
        joinStyle: ShapePath.MiterJoin
        startX: root.width * 0.25; startY: root.s
        PathLine { x: root.width * 0.75; y: root.s }
        PathLine { x: root.width - root.s; y: root.height / 2 }
        PathLine { x: root.width * 0.75; y: root.height - root.s }
        PathLine { x: root.width * 0.25; y: root.height - root.s }
        PathLine { x: root.s; y: root.height / 2 }
        PathLine { x: root.width * 0.25; y: root.s }
    }
    Behavior on fill { ColorAnimation { duration: Theme.fast } }
    Behavior on stroke { ColorAnimation { duration: Theme.fast } }
}
