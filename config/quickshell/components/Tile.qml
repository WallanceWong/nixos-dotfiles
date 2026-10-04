import QtQuick
import QtQuick.Layouts
import qs.services

// Toggle tile for the control centre: icon, title, a status line, and an
// optional ">" to open details.
Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool expandable: false
    signal toggled()
    signal expand()

    implicitHeight: 62
    radius: Theme.radiusSmall + 4
    color: active ? Qt.alpha(Theme.lamp, 0.15) : main.containsMouse ? Theme.surface1 : Theme.surface0
    border.width: 1
    border.color: active ? Qt.alpha(Theme.lamp, 0.35) : Theme.hairline
    Behavior on color { ColorAnimation { duration: Theme.normal } }
    Behavior on border.color { ColorAnimation { duration: Theme.normal } }

    MouseArea {
        id: main
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { root.toggled(); Sounds.play("toggle", 0.35); }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 6
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            radius: 18
            color: root.active ? Theme.lamp : Theme.surface2
            Behavior on color { ColorAnimation { duration: Theme.normal } }
            Icon {
                anchors.centerIn: parent
                icon: root.icon
                size: 19
                fill: root.active ? 1 : 0
                color: root.active ? Theme.base : Theme.text
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Label { Layout.fillWidth: true; text: root.title; font.pixelSize: 13; font.weight: Font.Bold; color: root.active ? Theme.lamp : Theme.text }
            Label { Layout.fillWidth: true; text: root.subtitle; font.pixelSize: 11; font.weight: Font.Medium; color: Theme.subtext; visible: text.length > 0 }
        }

        IconButton {
            visible: root.expandable
            icon: "chevron_right"
            iconSize: 18
            implicitWidth: 28
            implicitHeight: 28
            onClicked: root.expand()
        }
    }
}
