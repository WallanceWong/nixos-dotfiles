import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.components

// The wallpaper, per setup: the living painting (UNIT-01) or the MAGI command
// display (NERV HQ). The picture drifts sideways as you move between
// workspaces — depth.
Variants {
    // EVA_ONLY limits the shell to one screen (used for testing)
    model: Quickshell.screens.filter(s => !Quickshell.env("EVA_ONLY") || s.name === Quickshell.env("EVA_ONLY"))

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "eva-wallpaper"
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: Theme.crust

        readonly property int wsId: Hyprland.monitorFor(modelData)?.activeWorkspace?.id ?? 3

        Loader {
            anchors.fill: parent
            sourceComponent: Theme.magi ? magi : unit01
        }
        Component {
            id: unit01
            Unit01Scene {
                animate: Desktop.skyVisible
                // workspace 1 → shifted right, 5 → left
                shift: (3 - Math.max(1, Math.min(5, win.wsId))) * 22
            }
        }
        Component {
            id: magi
            MagiScene {
                animate: Desktop.skyVisible
                screenName: win.modelData.name
            }
        }
    }
}
