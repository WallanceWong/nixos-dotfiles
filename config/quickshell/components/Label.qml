import QtQuick
import qs.services

Text {
    color: Theme.text
    font.family: Theme.font
    font.pixelSize: 13
    font.weight: Font.DemiBold
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
    Behavior on color { ColorAnimation { duration: Theme.normal } }
}
