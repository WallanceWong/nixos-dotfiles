pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The active setup (UNIT-01 / SHINJI or NERV HQ / MAGI): colours, fonts, shape
// and motion come from ~/nixos-dotfiles/theme/setups/<id>.json; which one is
// active lives in ~/.local/state/eva/setup (written by eva-switch, see
// services/Setups.qml). Both files are watched, so a switch repaints live.
Singleton {
    id: root

    // EVA_DOTS points a test copy of the shell at its own repo
    readonly property string dots: Quickshell.env("EVA_DOTS") || (Quickshell.env("HOME") + "/nixos-dotfiles")
    readonly property string assets: Quickshell.shellDir + "/assets"
    readonly property string stateFile: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/eva/setup"

    FileView {
        id: activeFile
        path: root.stateFile
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
    }
    // EVA_SETUP forces one (testing); anything unknown falls back to unit01
    readonly property string setup: {
        const forced = Quickshell.env("EVA_SETUP");
        const s = (forced || activeFile.text() || "").trim();
        return s === "magi" ? "magi" : "unit01";
    }
    readonly property bool magi: setup === "magi"

    FileView {
        id: setupFile
        path: root.dots + "/theme/setups/" + root.setup + ".json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
    }
    readonly property var p: {
        try { return JSON.parse(setupFile.text()); } catch (e) { return {}; }
    }

    readonly property string name: p.name ?? "UNIT-01"
    readonly property string subtitle: p.subtitle ?? ""
    // full drama: klaxons, emergency banners, MAGI votes (NERV HQ); calm otherwise
    readonly property bool drama: p.drama ?? false

    readonly property color crust: p.crust ?? "#06071a"
    readonly property color mantle: p.mantle ?? "#0a0c24"
    readonly property color base: p.base ?? "#0f1331"
    readonly property color sunken: p.sunken ?? "#121738"
    readonly property color surface0: p.surface0 ?? "#172044"
    readonly property color surface1: p.surface1 ?? "#1e2a56"
    readonly property color surface2: p.surface2 ?? "#293a6b"
    readonly property color overlay: p.overlay ?? "#4b5c8c"
    readonly property color subtext: p.subtext ?? "#a7b2cf"
    readonly property color text: p.text ?? "#e8e5e1"

    readonly property color accent: p.accent ?? "#9be34a"       // the HUD's main colour
    readonly property color accentDim: p.accentDim ?? "#6fae30"
    readonly property color armour: p.armour ?? "#9a7fe6"       // second accent
    readonly property color signal: p.signal ?? "#9be34a"       // OK / charging / sync
    readonly property color info: p.info ?? "#68a6d0"           // network, pattern blue
    readonly property color caution: p.caution ?? "#ff9a4a"     // hazard, warnings
    readonly property color alert: p.alert ?? "#ff5d73"         // emergency

    // translucent panel surfaces (Hyprland blurs what is behind them)
    readonly property color glass: Qt.alpha(base, magi ? 0.90 : 0.82)
    readonly property color glassStrong: Qt.alpha(base, 0.95)
    readonly property color hairline: Qt.alpha(accent, magi ? 0.28 : 0.16)

    readonly property string font: p.font ?? "Barlow Semi Condensed"
    readonly property string hud: p.hud ?? "Barlow Condensed"        // caps labels, readouts
    readonly property string mono: p.mono ?? "JetBrainsMono Nerd Font"
    readonly property string title: p.title ?? "Noto Serif CJK JP"   // Eva title cards (heavy Mincho)
    readonly property string icons: "Material Symbols Sharp"

    readonly property int radius: p.radius ?? 3
    readonly property int radiusSmall: Math.max(0, radius - 1)
    readonly property int chamfer: magi ? 14 : 10                    // cut corner on HUD frames
    readonly property int gap: 8

    readonly property int fast: p.fast ?? 170
    readonly property int normal: p.normal ?? 280
    readonly property int slow: p.slow ?? 480
    readonly property int easing: magi ? Easing.OutQuart : Easing.OutCubic

    // icon by theme name ("firefox") or by file path ("/nix/store/…/kitty.png")
    function icon(name, fallback) {
        if (!name) return Quickshell.iconPath(fallback ?? "application-x-executable");
        if (name.startsWith("/")) return "file://" + name;
        if (name.startsWith("file:") || name.startsWith("image:")) return name;
        return Quickshell.iconPath(name, fallback ?? "application-x-executable");
    }
}
