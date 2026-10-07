//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark
import QtQuick
import Quickshell
import qs.modules

// whisper-shell — the desktop for the "whisper" rice (see README).
ShellRoot {
    Wallpaper {}
    Bar {}
    NotificationPopups {}
    Osd {}
    ControlCenter {}
    Dashboard {}
    Launcher {}
    Overview {}
    PowerMenu {}
    PolkitDialog {}
    Screensaver {}
    Lock {}
    Cheatsheet {}
    SettingsPanel {}
    Corners {}
    Shortcuts {}
}
