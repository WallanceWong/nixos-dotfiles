import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.services
import qs.components

// Overview: every workspace, with live previews of its windows.
// Click a window to go to it, drag it onto another workspace to move it.
PanelWindow {
    id: panel

    readonly property bool open: Panels.open === "overview"
    screen: Panels.screen
    visible: open || veil.opacity > 0
    WlrLayershell.namespace: "whisper-overview"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property real sw: monitor?.width ?? 1920
    readonly property real sh: monitor?.height ?? 1200
    readonly property real cardW: Math.min(340, (width - 80 - 4 * 20) / 5)
    readonly property real cardH: cardW * sh / sw
    readonly property real k: cardW / sw
    property int selected: 0

    onOpenChanged: if (open) {
        Hyprland.refreshToplevels();
        Hyprland.refreshWorkspaces();
        selected = Math.max(0, (monitor?.activeWorkspace?.id ?? 1) - 1);
        keys.forceActiveFocus();
    }

    function go(ws) { Panels.close(); Hyprland.dispatch("workspace " + ws); }

    Rectangle {
        id: veil
        anchors.fill: parent
        color: Qt.alpha(Theme.crust, 0.55)
        opacity: panel.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.normal; easing.type: Theme.easing } }
        MouseArea { anchors.fill: parent; onClicked: Panels.close() }
    }

    Item {
        id: keys
        focus: panel.open
        Keys.onEscapePressed: Panels.close()
        Keys.onLeftPressed: panel.selected = (panel.selected + 4) % 5
        Keys.onRightPressed: panel.selected = (panel.selected + 1) % 5
        Keys.onReturnPressed: panel.go(panel.selected + 1)
        Keys.onEnterPressed: panel.go(panel.selected + 1)
        Keys.onPressed: e => { if (e.key >= Qt.Key_1 && e.key <= Qt.Key_5) panel.go(e.key - Qt.Key_0); }
    }

    Column {
        anchors.centerIn: parent
        spacing: 22
        opacity: veil.opacity
        scale: 0.94 + 0.06 * veil.opacity

        Row {
            id: cards
            spacing: 20

            Repeater {
                model: 5
                Column {
                    id: wsCol
                    required property int index
                    readonly property int wsId: index + 1
                    readonly property bool current: panel.monitor?.activeWorkspace?.id === wsId
                    spacing: 10

                    DropArea {
                        id: drop
                        width: panel.cardW
                        height: panel.cardH
                        keys: ["whisper-window"]
                        onDropped: d => Hyprland.dispatch("movetoworkspacesilent " + wsCol.wsId + ",address:" + d.source.address)

                        ClippingRectangle {
                            id: card
                            anchors.fill: parent
                            radius: Theme.radius
                            color: Theme.crust
                            border.width: wsCol.current || panel.selected === wsCol.index || drop.containsDrag ? 2 : 1
                            border.color: drop.containsDrag ? Theme.teal : wsCol.current ? Theme.lamp : panel.selected === wsCol.index ? Qt.alpha(Theme.lamp, 0.6) : Theme.hairline

                            Image {
                                anchors.fill: parent
                                source: "file://" + Theme.dots + "/wallpapers/wall.jpg"
                                sourceSize.width: 480
                                fillMode: Image.PreserveAspectCrop
                                opacity: 0.85
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: panel.selected = wsCol.index
                                onClicked: panel.go(wsCol.wsId)
                            }

                            Repeater {
                                model: panel.open ? Hyprland.toplevels.values.filter(t => t.workspace?.id === wsCol.wsId) : []
                                Item {
                                    id: win
                                    required property var modelData
                                    readonly property var ipc: modelData.lastIpcObject
                                    readonly property string address: ipc?.address ?? ("0x" + modelData.address)
                                    // positions are relative to the window's own monitor
                                    readonly property var mon: modelData.monitor
                                    readonly property real homeX: ((ipc?.at?.[0] ?? 0) - (mon?.x ?? 0)) * panel.k
                                    readonly property real homeY: ((ipc?.at?.[1] ?? 0) - (mon?.y ?? 0)) * panel.k
                                    x: homeX
                                    y: homeY
                                    width: Math.max(24, (ipc?.size?.[0] ?? 200) * panel.k)
                                    height: Math.max(18, (ipc?.size?.[1] ?? 150) * panel.k)
                                    z: (ipc?.floating ?? false) ? 2 : 1

                                    Drag.active: dragArea.drag.active
                                    Drag.keys: ["whisper-window"]
                                    Drag.hotSpot.x: width / 2
                                    Drag.hotSpot.y: height / 2

                                    ClippingRectangle {
                                        anchors.fill: parent
                                        radius: 6
                                        color: Theme.surface0
                                        border.width: 1
                                        border.color: dragArea.containsMouse ? Theme.lamp : Qt.alpha(Theme.lamp, 0.25)
                                        ScreencopyView {
                                            anchors.fill: parent
                                            captureSource: panel.open ? win.modelData.wayland : null
                                            live: true
                                        }
                                        IconImage {
                                            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 4 }
                                            implicitSize: Math.min(26, parent.height * 0.4)
                                            source: Theme.icon(DesktopEntries.heuristicLookup(win.ipc?.class ?? "")?.icon ?? "application-x-executable", "application-x-executable")
                                        }
                                    }
                                    MouseArea {
                                        id: dragArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                        drag.target: win
                                        onReleased: {
                                            if (drag.active) { win.Drag.drop(); win.x = Qt.binding(() => win.homeX); win.y = Qt.binding(() => win.homeY); Qt.callLater(Hyprland.refreshToplevels); }
                                        }
                                        onClicked: { Panels.close(); Hyprland.dispatch("focuswindow address:" + win.address); }
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 6
                        Icon { icon: "star"; size: 16; fill: wsCol.current ? 1 : 0; color: wsCol.current ? Theme.lamp : Theme.subtext }
                        Label { text: String(wsCol.wsId); color: wsCol.current ? Theme.lamp : Theme.subtext; font.weight: Font.ExtraBold }
                    }
                }
            }
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "click to go   ·   drag a window to move it   ·   ← → Enter   ·   Esc"
            color: Theme.subtext
            font.pixelSize: 12
        }
    }
}
