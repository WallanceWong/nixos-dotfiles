import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.components

// The wallpaper: the living night (components/Scene.qml). The sky drifts
// sideways as you move between workspaces, slower than the foreground — depth.
Variants {
    // WHISPER_ONLY limits the shell to one screen (used for testing)
    model: Quickshell.screens.filter(s => !Quickshell.env("WHISPER_ONLY") || s.name === Quickshell.env("WHISPER_ONLY"))

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "whisper-wallpaper"
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: Theme.crust

        readonly property int wsId: Hyprland.monitorFor(modelData)?.activeWorkspace?.id ?? 3

        Scene {
            anchors.fill: parent
            animate: Desktop.skyVisible
            // workspace 1 → sky shifted right, 5 → left (the painting has room to spare)
            shift: (3 - Math.max(1, Math.min(5, win.wsId))) * 22
        }
    }
}
