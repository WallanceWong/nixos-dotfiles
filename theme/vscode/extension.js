// whisper — small touches that tie VS Code to the desktop: tonight's real moon
// (same maths as whisper-shell's Astro.qml) and the date in Japanese numerals,
// down in the status bar like the strip of street under the sky.
const vscode = require("vscode");

// monochrome so they take the lamp colour (emoji moons render as dark blobs)
const PHASES = ["●", "☽", "◐", "○", "○", "○", "◑", "☾"];
// the traditional Japanese names, to sit beside the Japanese date
const JP = ["新月", "三日月", "上弦", "十三夜", "満月", "居待月", "下弦", "有明月"];
const NAMES = ["new moon", "waxing crescent", "first quarter", "waxing gibbous",
               "full moon", "waning gibbous", "last quarter", "waning crescent"];

function moonPhase(d) {
    const synodic = 29.530588853;
    const days = (d.getTime() - Date.UTC(2000, 0, 6, 18, 14)) / 86400000;
    return (((days % synodic) + synodic) % synodic) / synodic;     // 0 new · 0.5 full
}

function kanji(n) {
    const d = ["", "一", "二", "三", "四", "五", "六", "七", "八", "九"];
    if (n < 10) return d[n];
    if (n === 10) return "十";
    if (n < 20) return "十" + d[n - 10];
    return d[Math.floor(n / 10)] + "十" + d[n % 10];
}

function activate(context) {
    const moon = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, -1000);
    moon.command = "whisper.moon";
    moon.color = new vscode.ThemeColor("whisper.moon");
    moon.name = "Whisper: tonight's moon";
    context.subscriptions.push(moon);

    const update = () => {
        const now = new Date();
        const p = moonPhase(now);
        const i = Math.round(p * 8) % 8;
        const lit = Math.round((1 - Math.cos(2 * Math.PI * p)) / 2 * 100);
        const date = kanji(now.getMonth() + 1) + "月" + kanji(now.getDate()) + "日";
        const day = ["日", "月", "火", "水", "木", "金", "土"][now.getDay()] + "曜日";
        moon.text = `${PHASES[i]} ${JP[i]}  ${date}`;
        const h = now.getHours();
        const mood = h < 4 ? "still up? the city has gone quiet below"
                   : h < 6 ? "the streetlamps are the only ones awake"
                   : h < 12 ? "morning light, the night will be back"
                   : h < 18 ? "the moon is out there somewhere, waiting"
                   : h < 21 ? "the lamps are coming on along the street"
                   : "a quiet night, the city still awake below";
        const tip = new vscode.MarkdownString(
            `**${JP[i]}** — ${NAMES[i]} · ${lit}% lit\n\n${date} ${day}\n\n*${mood}*`);
        moon.tooltip = tip;
        moon.show();
    };
    update();
    const timer = setInterval(update, 60 * 1000);
    context.subscriptions.push({ dispose: () => clearInterval(timer) });

    context.subscriptions.push(vscode.commands.registerCommand("whisper.moon", () => {
        const p = moonPhase(new Date());
        const i = Math.round(p * 8) % 8;
        const lit = Math.round((1 - Math.cos(2 * Math.PI * p)) / 2 * 100);
        const daysToFull = Math.round(((0.5 - p + 1) % 1) * 29.53);
        vscode.window.showInformationMessage(`${PHASES[i]}  ${NAMES[i]}, ${lit}% lit — full moon in ${daysToFull} day${daysToFull === 1 ? "" : "s"}.`);
    }));

    // night mode: zen, centred, nothing but the code under the lamp
    context.subscriptions.push(vscode.commands.registerCommand("whisper.night", () =>
        vscode.commands.executeCommand("workbench.action.toggleZenMode")));
}

function deactivate() {}
module.exports = { activate, deactivate };
