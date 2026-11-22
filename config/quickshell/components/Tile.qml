import QtQuick
import QtQuick.Layouts
import qs.services

// Toggle tile for the control centre: icon block, title, a status line, and
// an optional ">" to open details. Active = lit in the accent colour.
Item {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool expandable: false
    signal toggled()
    signal expand()

    implicitHeight: 60

    HudFrame {
        anchors.fill: parent
        cut: 9
        fill: root.active ? Qt.alpha(Theme.accent, Theme.magi ? 0.14 : 0.12) : main.containsMouse ? Theme.surface1 : Qt.alpha(Theme.surface0, 0.9)
        stroke: root.active ? Qt.alpha(Theme.accent, 0.6) : Theme.hairline
        ticks: root.active
    }

    MouseArea {
        id: main
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { root.toggled(); Sounds.play("toggle", 0.35); }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 6
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            color: root.active ? Theme.accent : Theme.surface2
            Behavior on color { ColorAnimation { duration: Theme.normal } }
            Icon {
                anchors.centerIn: parent
                icon: root.icon
                size: 19
                fill: root.active ? 1 : 0
                color: root.active ? Theme.crust : Theme.text
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Caps { Layout.fillWidth: true; text: root.title; font.pixelSize: 13; font.weight: Font.Bold; font.letterSpacing: 1; color: root.active ? Theme.accent : Theme.text }
            Label { Layout.fillWidth: true; text: root.subtitle; font.pixelSize: 12; font.weight: Font.Medium; color: Theme.subtext; visible: text.length > 0 }
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
