pragma Singleton
import QtQuick
import Quickshell

// UI sounds, played through PipeWire. Each setup has its own set
// (assets/sounds/<setup>/*.wav): quiet clicks and tape-deck clunks for UNIT-01,
// command-room beeps for NERV HQ. "alarm" is the klaxon (NERV HQ only, and only
// with Settings.klaxon on).
Singleton {
    id: root

    property double lastTick: 0

    function play(name, volume) {
        if (!Settings.sounds) return;
        if (name === "alarm" && !(Theme.drama && Settings.klaxon)) name = "deny";
        Quickshell.execDetached(["pw-play", "--volume", String(volume ?? 0.55),
                                 Theme.assets + "/sounds/" + Theme.setup + "/" + name + ".wav"]);
    }

    // volume ticks fire on every step; keep them from piling up
    function tick() {
        const now = Date.now();
        if (now - lastTick < 70) return;
        lastTick = now;
        play("tick", 0.4);
    }
}
