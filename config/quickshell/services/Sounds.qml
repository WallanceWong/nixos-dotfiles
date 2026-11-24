pragma Singleton
import QtQuick
import Quickshell

// UI sounds, played through PipeWire. Each setup has its own set
// (assets/sounds/<setup>/*.wav): quiet clicks for UNIT-01, Misato's
// "okaerinasai" when you come back and her launch order (発進！) when you
// switch to it; command-room beeps for NERV HQ, the real
// Pattern Blue klaxon ("alarm", only with Settings.klaxon on) and the AT field
// slamming shut on a wrong code. assets/sounds/common: sounds both share
// (the umbilical cable disconnecting when the charger comes out; the blast
// doors of the setup-switch sequences).
Singleton {
    id: root

    property double lastTick: 0
    readonly property var common: ["unplug", "door"]

    // `setup` picks another setup's set (the launch order plays before the switch)
    function play(name, volume, setup) {
        if (!Settings.sounds) return;
        if (name === "alarm" && !((setup ? setup === "magi" : Theme.drama) && Settings.klaxon)) name = "deny";
        const dir = common.includes(name) ? "common" : (setup ?? Theme.setup);
        Quickshell.execDetached(["pw-play", "--volume", String(volume ?? 0.55),
                                 Theme.assets + "/sounds/" + dir + "/" + name + ".wav"]);
    }

    // volume ticks fire on every step; keep them from piling up
    function tick() {
        const now = Date.now();
        if (now - lastTick < 70) return;
        lastTick = now;
        play("tick", 0.4);
    }
}
