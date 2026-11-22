import QtQuick
import qs.services

// Diagonal hazard stripes (amber/black by default). `running` makes them crawl.
Item {
    id: root
    property color color: Theme.caution
    property color gap: "transparent"
    property real stripe: 10
    property bool running: false
    clip: true

    Rectangle { anchors.fill: parent; color: root.gap }
    Item {
        id: band
        width: root.width + root.stripe * 4
        height: root.height
        x: -root.stripe * 2
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.stripe
            Repeater {
                model: Math.ceil((root.width + root.height + root.stripe * 6) / (root.stripe * 2))
                Rectangle {
                    width: root.stripe
                    height: root.height * 2.2
                    color: root.color
                    rotation: 45
                    antialiasing: true
                }
            }
        }
        NumberAnimation on x {
            running: root.running && root.visible
            from: -root.stripe * 2 * Math.SQRT2
            to: 0
            duration: 900
            loops: Animation.Infinite
        }
    }
}
