import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.services
import qs.components

// Notifications drift in at the top right, like notes passed at night.
PanelWindow {
    id: root

    screen: Panels.screen

    WlrLayershell.namespace: "whisper-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; right: true }
    margins { top: 58; right: 14 }
    implicitWidth: 392
    implicitHeight: Math.max(1, column.implicitHeight)
    color: "transparent"
    // quiet over fullscreen games; they still land in the history
    visible: Notifs.live.length > 0 && !Settings.gameMode && !Desktop.fullscreen

    // only the cards take clicks; empty space passes through
    mask: Region { item: column }

    Column {
        id: column
        width: parent.width
        spacing: 10

        Repeater {
            model: ScriptModel { values: Notifs.live.slice().reverse().slice(0, 5) }

            delegate: Item {
                id: card
                required property var modelData
                readonly property var n: modelData
                readonly property bool critical: n.urgency === NotificationUrgency.Critical
                width: column.width
                height: box.implicitHeight

                // slide in from the right
                property real slide: 1
                Component.onCompleted: slide = 0
                Behavior on slide { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }
                transform: Translate { x: card.slide * 420 }
                opacity: 1 - card.slide

                Timer {
                    running: !card.critical && !hover.containsMouse
                    interval: card.n.expireTimeout > 0 ? card.n.expireTimeout : 6000
                    onTriggered: card.n.expire()
                }

                Rectangle {
                    id: box
                    width: parent.width
                    implicitHeight: content.implicitHeight + 26
                    radius: Theme.radius
                    color: Theme.glassStrong
                    border.width: 1
                    border.color: card.critical ? Qt.alpha(Theme.red, 0.7) : Qt.alpha(Theme.lamp, 0.28)

                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: e => {
                            if (e.button === Qt.LeftButton) {
                                const def = card.n.actions.find(a => a.identifier === "default");
                                if (def) def.invoke();
                            }
                            card.n.dismiss();
                        }
                    }

                    RowLayout {
                        id: content
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 13 }
                        spacing: 12

                        ClippingRectangle {
                            Layout.preferredWidth: 42
                            Layout.preferredHeight: 42
                            Layout.alignment: Qt.AlignTop
                            radius: 12
                            color: Theme.surface0
                            IconImage {
                                anchors.fill: parent
                                anchors.margins: card.n.image ? 0 : 6
                                source: Notifs.iconFor(card.n)
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3
                            RowLayout {
                                Layout.fillWidth: true
                                Label { Layout.fillWidth: true; text: card.n.summary; font.pixelSize: 14; font.weight: Font.Bold; color: card.critical ? Theme.red : Theme.lamp }
                                Label { text: card.n.appName; font.pixelSize: 11; color: Theme.overlay }
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: text.length > 0
                                text: card.n.body
                                textFormat: Text.StyledText
                                wrapMode: Text.Wrap
                                maximumLineCount: 4
                                elide: Text.ElideRight
                                color: Theme.subtext
                                font.family: Theme.font
                                font.pixelSize: 13
                            }
                            Flow {
                                Layout.fillWidth: true
                                Layout.topMargin: 6
                                spacing: 6
                                visible: card.n.actions.filter(a => a.identifier !== "default").length > 0
                                Repeater {
                                    model: card.n.actions.filter(a => a.identifier !== "default")
                                    Rectangle {
                                        required property var modelData
                                        width: actionText.implicitWidth + 24
                                        height: 28
                                        radius: 14
                                        color: actionMouse.containsMouse ? Theme.surface2 : Theme.surface1
                                        Label { id: actionText; anchors.centerIn: parent; text: parent.modelData.text; font.pixelSize: 12 }
                                        MouseArea { id: actionMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { parent.modelData.invoke(); card.n.dismiss(); } }
                                    }
                                }
                            }
                        }
                    }

                    // progress hint (e.g. downloads) as a thin teal line along the bottom
                    Rectangle {
                        readonly property var v: card.n.hints?.value
                        visible: v !== undefined
                        anchors { left: parent.left; bottom: parent.bottom; leftMargin: 14; bottomMargin: 7 }
                        height: 3; radius: 2
                        width: (parent.width - 28) * Math.max(0, Math.min(100, v ?? 0)) / 100
                        color: Theme.teal
                    }
                }
            }
        }
    }
}
