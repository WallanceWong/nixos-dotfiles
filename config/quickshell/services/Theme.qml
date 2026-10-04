pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// whisper — colours come from ~/nixos-dotfiles/theme/palette.json (the one palette),
// plus the shared fonts, sizes and motion used across the shell.
Singleton {
    id: root

    readonly property string dots: Quickshell.env("HOME") + "/nixos-dotfiles"
    readonly property string assets: Quickshell.shellDir + "/assets"

    FileView {
        id: paletteFile
        path: root.dots + "/theme/palette.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
    }
    readonly property var p: {
        try { return JSON.parse(paletteFile.text()); } catch (e) { return {}; }
    }

    readonly property color crust: p.crust ?? "#030b12"
    readonly property color mantle: p.mantle ?? "#05131e"
    readonly property color base: p.base ?? "#071a28"
    readonly property color surface0: p.surface0 ?? "#0c2a3d"
    readonly property color surface1: p.surface1 ?? "#13384e"
    readonly property color surface2: p.surface2 ?? "#1d4a60"
    readonly property color overlay: p.overlay ?? "#3f6e74"
    readonly property color subtext: p.subtext ?? "#9fb5bd"
    readonly property color text: p.text ?? "#e3e8e1"
    readonly property color lamp: p.lamp ?? "#f0e3a8"
    readonly property color lampDim: p.lampDim ?? "#c9b979"
    readonly property color teal: p.teal ?? "#7fc3c6"
    readonly property color blue: p.blue ?? "#6d9fd1"
    readonly property color red: p.red ?? "#e0786c"
    readonly property color mustard: p.mustard ?? "#e3b35c"
    readonly property color green: p.green ?? "#8fbf9a"
    readonly property color violet: p.violet ?? "#b69ad6"

    // translucent panel surfaces (Hyprland blurs what is behind them)
    readonly property color glass: Qt.alpha(base, 0.84)
    readonly property color glassStrong: Qt.alpha(base, 0.94)
    readonly property color hairline: Qt.alpha(lamp, 0.12)

    readonly property string font: "Nunito"
    readonly property string mono: "JetBrainsMono Nerd Font"
    readonly property string icons: "Material Symbols Rounded"
    readonly property string jp: "Noto Serif CJK JP"

    readonly property int radius: 16
    readonly property int radiusSmall: 11
    readonly property int gap: 8

    // motion: soft and unhurried, like night air
    readonly property int fast: 160
    readonly property int normal: 260
    readonly property int slow: 420
    readonly property int easing: Easing.OutCubic

    // icon by theme name ("firefox") or by file path ("/nix/store/…/kitty.png")
    function icon(name, fallback) {
        if (!name) return Quickshell.iconPath(fallback ?? "application-x-executable");
        if (name.startsWith("/")) return "file://" + name;
        if (name.startsWith("file:") || name.startsWith("image:")) return name;
        return Quickshell.iconPath(name, fallback ?? "application-x-executable");
    }
}
