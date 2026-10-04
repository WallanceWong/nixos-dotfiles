pragma Singleton
import QtQuick
import Quickshell

// Soft UI sounds (assets/sounds/*.wav), played through PipeWire.
Singleton {
    id: root

    property double lastTick: 0

    function play(name, volume) {
        if (!Settings.sounds) return;
        Quickshell.execDetached(["pw-play", "--volume", String(volume ?? 0.55),
                                 Theme.assets + "/sounds/" + name + ".wav"]);
    }

    // volume ticks fire on every step; keep them from piling up
    function tick() {
        const now = Date.now();
        if (now - lastTick < 70) return;
        lastTick = now;
        play("tick", 0.4);
    }
}
