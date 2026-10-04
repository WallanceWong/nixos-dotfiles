import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services

// Rounded screen corners: four tiny click-through surfaces per monitor that
// paint the corners night-black. Hidden for fullscreen apps and game mode.
Variants {
    model: Settings.corners ? Quickshell.screens.filter(s => !Quickshell.env("WHISPER_ONLY") || s.name === Quickshell.env("WHISPER_ONLY")) : []

    Scope {
        id: scr
        required property var modelData
        readonly property var monitor: Hyprland.monitorFor(modelData)
        readonly property bool hidden: Settings.gameMode || (!!Hyprland.activeToplevel?.wayland?.fullscreen && Hyprland.focusedMonitor === monitor)
        readonly property int r: 14

        Variants {
            model: ["tl", "tr", "bl", "br"]
            PanelWindow {
                id: corner
                required property string modelData
                readonly property bool isTop: modelData[0] === "t"
                readonly property bool isLeft: modelData[1] === "l"
                screen: scr.modelData
                visible: !scr.hidden
                anchors { top: corner.isTop; bottom: !corner.isTop; left: corner.isLeft; right: !corner.isLeft }
                implicitWidth: scr.r
                implicitHeight: scr.r
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "whisper-corner"
                color: "transparent"
                mask: Region {}

                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    // quarter-circle cut-out: fill the corner, leave the arc
                    transform: Scale {
                        origin.x: scr.r / 2; origin.y: scr.r / 2
                        xScale: corner.isLeft ? 1 : -1
                        yScale: corner.isTop ? 1 : -1
                    }
                    ShapePath {
                        fillColor: "black"
                        strokeColor: "transparent"
                        startX: 0; startY: 0
                        PathLine { x: scr.r; y: 0 }
                        PathArc { x: 0; y: scr.r; radiusX: scr.r; radiusY: scr.r; direction: PathArc.Counterclockwise }
                        PathLine { x: 0; y: 0 }
                    }
                }
            }
        }
    }
}
