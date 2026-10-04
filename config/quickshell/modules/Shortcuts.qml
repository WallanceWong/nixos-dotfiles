import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services

// Keys from hyprland.conf ("global, quickshell:<name>") and an IPC target
// (`qs ipc call whisper <fn>`) that drive the shell.
Scope {
    component Shortcut: GlobalShortcut { appid: "quickshell" }

    Shortcut { name: "launcher"; description: "App launcher"; onPressed: Panels.launcher("apps") }
    Shortcut { name: "clipboard"; description: "Clipboard history"; onPressed: Panels.launcher("clipboard") }
    Shortcut { name: "emoji"; description: "Emoji picker"; onPressed: Panels.launcher("emoji") }
    Shortcut { name: "windows"; description: "Window switcher"; onPressed: Panels.launcher("windows") }
    Shortcut { name: "overview"; description: "Workspace overview"; onPressed: Panels.toggle("overview") }
    Shortcut { name: "control"; description: "Control centre"; onPressed: Panels.toggle("control") }
    Shortcut { name: "dashboard"; description: "Dashboard"; onPressed: Panels.toggle("dashboard") }
    Shortcut { name: "power"; description: "Power menu"; onPressed: Panels.toggle("power") }
    Shortcut { name: "gamemode"; description: "Toggle game mode"; onPressed: Desktop.setGameMode(!Settings.gameMode) }
    Shortcut { name: "dnd"; description: "Toggle do not disturb"; onPressed: Settings.dnd = !Settings.dnd }
    Shortcut { name: "record"; description: "Record a region"; onPressed: Recorder.toggle(true) }
    Shortcut { name: "recordscreen"; description: "Record the whole screen"; onPressed: Recorder.toggle(false) }
    Shortcut { name: "brightness"; description: "Show brightness"; onPressed: brightnessDelay.restart() }
    Shortcut { name: "ime"; description: "Switch English / Chinese"; onPressed: Ime.toggle() }
    Shortcut { name: "cheatsheet"; description: "Keyboard shortcuts"; onPressed: Panels.toggle("cheatsheet") }
    Shortcut { name: "settings"; description: "whisper settings"; onPressed: Panels.toggle("settings") }

    // brightnessctl runs from the same key; read the new value a moment later
    Timer { id: brightnessDelay; interval: 90; onTriggered: Brightness.refresh(true) }

    IpcHandler {
        target: "whisper"
        function toggle(name: string): void { Panels.toggle(name); }
        function launcher(mode: string): void { Panels.launcher(mode); }
        function close(): void { Panels.close(); }
        function brightness(): void { Brightness.refresh(true); }
        function gamemode(): void { Desktop.setGameMode(!Settings.gameMode); }
        function lock(): void { Locker.lock(); }
        function launch(id: string): void { const e = DesktopEntries.byId(id) ?? DesktopEntries.heuristicLookup(id); if (e) Desktop.launchEntry(e); }
        function locked(): bool { return Locker.locked; }
        // Feral GameMode hooks (programs.gamemode.settings.custom)
        function gamestart(): void { Automations.gameStarted(); }
        function gameend(): void { Automations.gameEnded(); }
        function notify(): void { Quickshell.execDetached(["notify-send", "-a", "whisper", "-i", "weather-clear-night", "a quiet night", "the city is still awake below"]); }
    }
}
