import QtQuick
import qs.services

// Two armoured half-doors that meet in the middle (the setup-switch sequences,
// modules/Launch.qml and modules/Scramble.qml). `shut` 0 = open, 1 = closed.
Item {
    id: doors
    property real shut: 0
    property color edge: Theme.caution
    property color plate: "#0b0c14"
    property string label: ""

    component Half: Item {
        id: half
        property bool upper
        width: doors.width
        height: Math.ceil(doors.height / 2) + 1
        y: upper ? -height * (1 - doors.shut) : doors.height - height + height * (1 - doors.shut)
        visible: doors.shut > 0

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: half.upper ? Qt.darker(doors.plate, 1.4) : doors.plate }
                GradientStop { position: 1; color: half.upper ? doors.plate : Qt.darker(doors.plate, 1.4) }
            }
        }
        // armour seams
        Repeater {
            model: 5
            Rectangle {
                required property int index
                width: half.width; height: 1
                y: half.height * (index + 1) / 6
                color: Qt.alpha(doors.edge, 0.10)
            }
        }
        Repeater {
            model: 6
            Rectangle {
                required property int index
                width: 1; height: half.height
                x: half.width * (index + 1) / 7
                color: Qt.alpha("white", 0.03)
            }
        }
        // the hazard edge where the halves meet
        Hazard {
            width: half.width; height: 30
            y: half.upper ? half.height - height : 0
            color: doors.edge
            gap: doors.plate
            stripe: 18
        }
        Text {
            x: 40
            y: half.upper ? half.height - 30 - height - 12 : 30 + 12
            text: doors.label
            color: Qt.alpha(doors.edge, 0.55)
            font { family: Theme.hud; pixelSize: 16; letterSpacing: 5; weight: Font.Bold }
        }
    }

    Half { upper: true }
    Half { upper: false }
}
