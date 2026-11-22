import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.services
import qs.components

// Notifications slide in at the top right as HUD cards. Critical ones raise a
// 警告 WARNING banner (with hazard stripes and the klaxon in NERV HQ).
PanelWindow {
    id: root

    screen: Panels.screen

    WlrLayershell.namespace: "eva-notifications"
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

                // the klaxon, once, for critical messages (NERV HQ only)
                Timer { running: card.critical && Theme.drama; interval: 10; onTriggered: Sounds.play("alarm", 0.5) }

                Item {
                    id: box
                    width: parent.width
                    implicitHeight: content.implicitHeight + 26 + (card.critical ? banner.height : 0)
                    readonly property color tone: card.critical ? Theme.alert : Theme.accent

                    HudFrame {
                        anchors.fill: parent
                        fill: Theme.glassStrong
                        stroke: Qt.alpha(box.tone, card.critical ? 0.85 : 0.45)
                        strokeWidth: card.critical ? 1.5 : 1
                        cut: 14
                        ticks: true
                        tickColor: box.tone
                    }
                    Rectangle { x: 0; y: 14; width: 3; height: parent.height - 28; color: box.tone }

                    // 警告 banner for critical messages
                    Item {
                        id: banner
                        visible: card.critical
                        x: 14; y: 8
                        width: parent.width - 28
                        height: 30
                        Hazard {
                            anchors.fill: parent
                            color: Qt.alpha(Theme.alert, 0.9)
                            gap: Qt.alpha(Theme.crust, 0.9)
                            stripe: 9
                            running: Theme.drama
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: warnRow.implicitWidth + 20
                            height: parent.height
                            color: Theme.crust
                            Row {
                                id: warnRow
                                anchors.centerIn: parent
                                spacing: 8
                                Text { text: "警告"; color: Theme.alert; font.family: Theme.title; font.weight: Font.Black; font.pixelSize: 17; anchors.verticalCenter: parent.verticalCenter }
                                Caps { text: "WARNING"; color: Theme.alert; font.pixelSize: 14; font.weight: Font.Bold; font.letterSpacing: 4 }
                            }
                        }
                        SequentialAnimation on opacity {
                            running: card.critical && Theme.drama
                            loops: 6
                            NumberAnimation { to: 0.35; duration: 260 }
                            NumberAnimation { to: 1; duration: 260 }
                        }
                    }

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
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 13; leftMargin: 16; topMargin: 13 + (card.critical ? banner.height + 6 : 0) }
                        spacing: 12

                        ClippingRectangle {
                            Layout.preferredWidth: 42
                            Layout.preferredHeight: 42
                            Layout.alignment: Qt.AlignTop
                            radius: 0
                            color: Theme.surface0
                            border.width: 1
                            border.color: Theme.hairline
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
                                Label { Layout.fillWidth: true; text: card.n.summary; font.pixelSize: 15; font.weight: Font.Bold; color: card.critical ? Theme.alert : Theme.text }
                                Caps { text: card.n.appName; font.pixelSize: 10; color: box.tone }
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
                                        color: actionMouse.containsMouse ? Qt.alpha(box.tone, 0.2) : Theme.surface1
                                        border.width: 1
                                        border.color: Qt.alpha(box.tone, actionMouse.containsMouse ? 0.8 : 0.3)
                                        Caps { id: actionText; anchors.centerIn: parent; text: parent.modelData.text; font.pixelSize: 12; color: Theme.text }
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
                        height: 3
                        width: (parent.width - 28) * Math.max(0, Math.min(100, v ?? 0)) / 100
                        color: box.tone
                    }
                }
            }
        }
    }
}
