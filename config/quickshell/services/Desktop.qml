pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
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
            effects(false, true);
        } else {
            Settings.dnd = dndBeforeGame;
            restoreEffects();
        }
        Sounds.play("toggle");
    }

    // ── talking to Hyprland ──
    // Hyprland is configured in Lua (config/hypr/hyprland.lua): dispatchers are
    // Lua expressions and options change through `hyprctl eval`. The old
    // hyprlang forms are kept for a Hyprland still running a .conf (until it
    // restarts after the switch to Lua).
    property bool luaMode: true
    Process {
        id: modeProbe
        running: true
        command: ["hyprctl", "eval", "return 0"]
        stdout: StdioCollector { onStreamFinished: root.luaMode = text.trim() === "ok" }
    }
    Connections {
        target: Hyprland
        function onRawEvent(e) { if (e.name === "configreloaded") modeProbe.running = true; }
    }
    function q(v) { return JSON.stringify(String(v)); }
    function dispatch(lua, legacy) { Hyprland.dispatch(luaMode ? lua : legacy); }
    function workspace(ws) { dispatch("hl.dsp.focus({ workspace = " + q(ws) + " })", "workspace " + ws); }
    function focusWindow(addr) { dispatch("hl.dsp.focus({ window = " + q("address:" + addr) + " })", "focuswindow address:" + addr); }
    function moveWindowSilent(addr, ws) {
        dispatch("hl.dsp.window.move({ workspace = " + q(ws) + ", follow = false, window = " + q("address:" + addr) + " })",
                 "movetoworkspacesilent " + ws + ",address:" + addr);
    }
    function exitSession() { dispatch("hl.dsp.exit()", "exit"); }
    // effects off (game mode, battery saver); `bare` also drops gaps, rounding, borders
    function effects(on, bare) {
        if (on) { restoreEffects(); return; }
        if (luaMode) {
            Quickshell.execDetached(["hyprctl", "eval", "hl.config({ animations = { enabled = false }, decoration = { blur = { enabled = false }, shadow = { enabled = false }"
                + (bare ? ", dim_inactive = false, rounding = 0 }, general = { gaps_in = 0, gaps_out = 0, border_size = 1 } })" : " } })")]);
        } else {
            Quickshell.execDetached(["hyprctl", "--batch", "keyword animations:enabled 0; keyword decoration:blur:enabled 0; keyword decoration:shadow:enabled 0"
                + (bare ? "; keyword decoration:dim_inactive 0; keyword general:gaps_in 0; keyword general:gaps_out 0; keyword decoration:rounding 0; keyword general:border_size 1" : "")]);
        }
    }
    // back to the config (and the setup's look); the border shimmer rests on battery
    function restoreEffects() {
        Quickshell.execDetached(["hyprctl", "reload"]);
        borderRest.restart();
    }
    Timer { id: borderRest; interval: 600; onTriggered: root.restBorder(Automations.onBattery) }
    // the shimmering window border redraws the screen every frame (~2% CPU, and
    // the GPU never idles): keep it on the charger, rest it on battery
    function restBorder(rest) {
        if (Settings.gameMode) return;
        if (luaMode) Quickshell.execDetached(["hyprctl", "eval", rest ? "hl.animation({ leaf = \"borderangle\", enabled = false })" : "EvaLoadSetup()"]);
        else Quickshell.execDetached(["hyprctl", "keyword", "animation", rest ? "borderangle,0" : "borderangle,1,100,linear,loop"]);
    }

    // Apps start in their own systemd scope (like apps started from a key bind),
    // not inside nerv-shell's service — restarting or crashing the shell
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
