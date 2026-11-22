// eva — small touches that tie VS Code to the desktop: the date in Japanese
// numerals, title-card style, down in the status bar, and an "entry plug"
// focus mode.
const vscode = require("vscode");

function kanji(n) {
    const d = ["〇", "一", "二", "三", "四", "五", "六", "七", "八", "九"];
    if (n < 10) return d[n];
    if (n < 20) return "十" + (n > 10 ? d[n - 10] : "");
    return d[Math.floor(n / 10)] + "十" + (n % 10 ? d[n % 10] : "");
}

// lines for the tooltip, by hour
function line(h) {
    return h < 5 ? "pilot, it's late — the MAGI will keep watch"
         : h < 12 ? "morning in Tokyo-3 · all systems nominal"
         : h < 18 ? "the cicadas are loud today"
         : h < 22 ? "evening · the city's lights come on"
         : "the Geofront never sleeps";
}

function activate(context) {
    const item = vscode.window.createStatusBarItem("eva.date", vscode.StatusBarAlignment.Left, -1000);
    item.command = "eva.date";
    item.color = new vscode.ThemeColor("eva.statusAccent");
    item.name = "Eva: today";
    context.subscriptions.push(item);

    const update = () => {
        const now = new Date();
        const date = kanji(now.getMonth() + 1) + "月" + kanji(now.getDate()) + "日";
        const day = ["日", "月", "火", "水", "木", "金", "土"][now.getDay()] + "曜日";
        item.text = `◢ ${date}`;
        item.tooltip = new vscode.MarkdownString(`**${date} ${day}**\n\n*${line(now.getHours())}*`);
        item.show();
    };
    update();
    const timer = setInterval(update, 60 * 1000);
    context.subscriptions.push({ dispose: () => clearInterval(timer) });

    context.subscriptions.push(vscode.commands.registerCommand("eva.date", () => {
        const now = new Date();
        vscode.window.showInformationMessage(`${kanji(now.getMonth() + 1)}月${kanji(now.getDate())}日 — ${now.toDateString()}`);
    }));
    // entry plug: zen, centred, nothing but the code
    context.subscriptions.push(vscode.commands.registerCommand("eva.focus", () =>
        vscode.commands.executeCommand("workbench.action.toggleZenMode")));
}

function deactivate() {}
module.exports = { activate, deactivate };
