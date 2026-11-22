import QtQuick
import qs.services

Text {
    color: Theme.text
    font.family: Theme.font
    font.pixelSize: 14
    font.weight: Font.Medium
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
    Behavior on color { ColorAnimation { duration: Theme.normal } }
}
