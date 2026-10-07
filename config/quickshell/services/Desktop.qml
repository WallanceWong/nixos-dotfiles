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

    // Apps start in their own systemd scope (like apps started from a key bind),
    // not inside whisper-shell's service — restarting or crashing the shell
    // would otherwise take every app opened from the launcher down with it.
    function launch(cmd, cwd) {
        const inDir = cwd ? ["sh", "-c", "cd \"$0\" && exec \"$@\"", cwd] : [];
        Quickshell.execDetached(["systemd-run", "--user", "--scope", "--slice=app.slice", "--collect", "--quiet", "--"]
                                .concat(inDir, cmd));
    }
    function launchEntry(e) {
        launch(e.runInTerminal ? ["kitty", "-e"].concat(e.command) : e.command, e.workingDirectory);
    }

    // screensaver (modules/Screensaver.qml), started by hypridle
    property bool saver: false
    function startSaver() {
        if (!Settings.screensaver || Locker.locked || Settings.gameMode || fullscreen) return;
        Panels.close();
        saver = true;
    }
    function stopSaver() { saver = false; }

    // When a monitor goes away (unplugged, or a test output removed), Qt can
    // leave the remaining screens' surfaces blank — wallpaper and bar vanish.
    // A quiet reload a moment later redraws everything.
    property int lastScreens: Quickshell.screens.length
    readonly property int screenCount: Quickshell.screens.length
    onScreenCountChanged: {
        if (screenCount < lastScreens) redraw.restart();
        lastScreens = screenCount;
    }
    Timer { id: redraw; interval: 1500; onTriggered: Quickshell.reload(false) }
}
