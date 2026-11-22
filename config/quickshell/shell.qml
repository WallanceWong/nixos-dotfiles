//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark
import QtQuick
import Quickshell
import qs.modules

// nerv-shell — the desktop for the eva rice (see README): two setups,
// UNIT-01 / SHINJI and NERV HQ / MAGI, switched with Super+Shift+U.
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
    MagiAsk {}
    Corners {}
    Shortcuts {}
}
