import QtQuick
import qs.services

// Material Symbols Rounded, referenced by name ("wifi", "volume_up", ...).
Text {
    id: root

    property string icon: ""
    property real size: 20
    property real fill: 0          // 0 outline, 1 filled
    property int weight: 400

    text: icon
    color: Theme.text
    font.family: Theme.icons
    font.pixelSize: size
    font.variableAxes: ({ "FILL": fill, "wght": weight, "opsz": Math.max(20, Math.min(48, size)), "GRAD": 0 })
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering

    Behavior on fill { NumberAnimation { duration: Theme.normal; easing.type: Theme.easing } }
    Behavior on color { ColorAnimation { duration: Theme.normal } }
}
