import QtQuick
import qs.services

// Seven-segment display ("03:59", "41.2"), like the Eva's internal power timer.
// Unlit segments stay faintly visible.
Row {
    id: root
    property string text: "00:00"
    property real digitHeight: 32
    property color color: Theme.alert
    property real dim: 0.07
    property real slant: 0.12                 // italic lean
    readonly property real dw: digitHeight * 0.52
    readonly property real t: Math.max(2, digitHeight * 0.11)   // segment thickness
    spacing: digitHeight * 0.12

    //  a
    // f b
    //  g
    // e c
    //  d
    readonly property var map: ({
        "0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc", "5": "afgcd",
        "6": "afgedc", "7": "abc", "8": "abcdefg", "9": "abcdfg", "-": "g", " ": "", "E": "afged",
        "r": "eg", "o": "cdeg", "P": "abefg", "A": "abcefg", "L": "fed", "F": "aefg"
    })

    Repeater {
        model: root.text.split("")
        Item {
            id: cell
            required property string modelData
            readonly property bool punct: modelData === ":" || modelData === "."
            width: punct ? root.t * 1.6 : root.dw
            height: root.digitHeight
            transform: Shear { xFactor: -root.slant; origin.y: cell.height }

            Repeater {
                model: cell.punct ? (cell.modelData === ":" ? 2 : 1) : 0
                Rectangle {
                    required property int index
                    width: root.t; height: root.t
                    x: (cell.width - width) / 2
                    y: cell.modelData === "." ? cell.height - root.t : (index === 0 ? cell.height * 0.28 : cell.height * 0.66)
                    color: root.color
                }
            }

            Canvas {
                visible: !cell.punct
                anchors.fill: parent
                antialiasing: true
                readonly property string lit: root.map[cell.modelData] ?? ""
                readonly property color on: root.color
                onLitChanged: requestPaint()
                onOnChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const w = width, h = height, t = root.t, m = t / 2, g = t * 0.18;
                    // each segment as a hexagon: horizontal at y, or vertical from y0 to y1 at x
                    const hor = y => [[g + m, y], [g + t, y - m], [w - g - t, y - m], [w - g - m, y], [w - g - t, y + m], [g + t, y + m]];
                    const ver = (x, y0, y1) => [[x, y0], [x + m, y0 + m], [x + m, y1 - m], [x, y1], [x - m, y1 - m], [x - m, y0 + m]];
                    const segs = {
                        a: hor(m), g: hor(h / 2), d: hor(h - m),
                        f: ver(m, g + m, h / 2 - g), b: ver(w - m, g + m, h / 2 - g),
                        e: ver(m, h / 2 + g, h - g - m), c: ver(w - m, h / 2 + g, h - g - m)
                    };
                    for (const k in segs) {
                        const pts = segs[k];
                        ctx.fillStyle = lit.indexOf(k) >= 0 ? on : Qt.alpha(on, root.dim);
                        ctx.beginPath();
                        ctx.moveTo(pts[0][0], pts[0][1]);
                        for (let i = 1; i < pts.length; i++) ctx.lineTo(pts[i][0], pts[i][1]);
                        ctx.closePath();
                        ctx.fill();
                    }
                }
            }
        }
    }
}
