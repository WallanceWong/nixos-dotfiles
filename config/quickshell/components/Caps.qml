import QtQuick
import qs.services

// HUD caption: condensed capitals with wide tracking ("SYNC RATIO", "UNIT-01").
Text {
    color: Theme.subtext
    font.family: Theme.hud
    font.pixelSize: 11
    font.weight: Font.DemiBold
    font.capitalization: Font.AllUppercase
    font.letterSpacing: 1.6
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
    Behavior on color { ColorAnimation { duration: Theme.normal } }
}
