pragma Singleton
import QtQuick
import Quickshell

// The real sky over Kuching, worked out on the laptop (no internet):
// how high the sun is, and tonight's moon phase. Updated once a minute.
Singleton {
    id: root

    readonly property real lat: 1.5535
    readonly property real lon: 110.3593

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // degrees above (+) or below (−) the horizon
    readonly property real sunAltitude: sunAlt(clock.date)
    // 0 = new moon, 0.25 = first quarter, 0.5 = full, 0.75 = last quarter
    readonly property real moonPhase: phase(clock.date)
    readonly property real moonLit: (1 - Math.cos(2 * Math.PI * moonPhase)) / 2
    readonly property bool waxing: moonPhase < 0.5
    readonly property string moonName: {
        const p = moonPhase;
        if (p < 0.03 || p > 0.97) return "new moon";
        if (p < 0.22) return "waxing crescent";
        if (p < 0.28) return "first quarter";
        if (p < 0.47) return "waxing gibbous";
        if (p < 0.53) return "full moon";
        if (p < 0.72) return "waning gibbous";
        if (p < 0.78) return "last quarter";
        return "waning crescent";
    }

    // night 0..1 (deepest after midnight), twilight 0..1 (warm edge), day 0..1 (haze)
    readonly property real night: Math.max(0, Math.min(1, (-sunAltitude - 12) / 45))
    readonly property real twilight: Math.max(0, 1 - Math.abs(sunAltitude + 3) / 9)
    readonly property real day: Math.max(0, Math.min(1, (sunAltitude - 4) / 30))

    function phase(date) {
        const synodic = 29.530588853;
        const days = (date.getTime() - Date.UTC(2000, 0, 6, 18, 14)) / 86400000;
        return (((days % synodic) + synodic) % synodic) / synodic;
    }

    // low-precision solar position (good to a fraction of a degree)
    function sunAlt(date) {
        const rad = Math.PI / 180;
        const d = (date.getTime() - Date.UTC(2000, 0, 1, 12)) / 86400000;
        const g = (357.529 + 0.98560028 * d) * rad;
        const q = 280.459 + 0.98564736 * d;
        const L = (q + 1.915 * Math.sin(g) + 0.020 * Math.sin(2 * g)) * rad;
        const e = (23.439 - 0.00000036 * d) * rad;
        const ra = Math.atan2(Math.cos(e) * Math.sin(L), Math.cos(L));
        const dec = Math.asin(Math.sin(e) * Math.sin(L));
        const gmst = ((18.697374558 + 24.06570982441908 * d) % 24 + 24) % 24;
        const ha = (gmst * 15 + lon) * rad - ra;
        return Math.asin(Math.sin(lat * rad) * Math.sin(dec) + Math.cos(lat * rad) * Math.cos(dec) * Math.cos(ha)) / rad;
    }
}
