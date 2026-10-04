pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// What the desktop is doing right now: is the night sky visible, is
// something fullscreen, is game mode on.
Singleton {
    id: root

    readonly property var workspace: Hyprland.focusedWorkspace
    readonly property int windowCount: workspace?.toplevels?.values?.length ?? 0
    // true fullscreen only (games, videos) — maximised windows don't count
    readonly property bool fullscreen: !!Hyprland.activeToplevel?.wayland?.fullscreen

    // animate the living wallpaper only when nothing covers it
    readonly property bool skyVisible: windowCount === 0 && !Settings.gameMode && !Automations.saving

    property bool dndBeforeGame: false

    function setGameMode(on) {
        if (on === Settings.gameMode) return;
        Settings.gameMode = on;
        if (on) {
            dndBeforeGame = Settings.dnd;
            Settings.dnd = true;
            Hyprland.dispatch("exec hyprctl --batch 'keyword animations:enabled 0; keyword decoration:blur:enabled 0; keyword decoration:shadow:enabled 0; keyword decoration:dim_inactive 0; keyword general:gaps_in 0; keyword general:gaps_out 0; keyword decoration:rounding 0; keyword general:border_size 1'");
        } else {
            Settings.dnd = dndBeforeGame;
            Hyprland.dispatch("exec hyprctl reload");
        }
        Sounds.play("toggle");
    }
}
