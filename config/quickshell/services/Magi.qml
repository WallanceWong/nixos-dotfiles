pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Ask the MAGI: a question goes to the local language model (Ollama, on this
// laptop — nothing leaves it), which answers as MELCHIOR-1, BALTHASAR-2 and
// CASPER-3, each with a reason and a vote. Asked from the NERV HQ wallpaper
// (components/MagiScene.qml), whose three computers show the vote. The model
// is unloaded as soon as it answers, so its ~5 GB of memory comes straight back.
Singleton {
    id: root

    property string question: ""
    property bool busy: false
    property string error: ""
    property var votes: []              // [{ name, reason, yes }] × 3, once answered
    property double askedAt: 0
    property double tookMs: 0
    readonly property int approvals: votes.filter(v => v.yes).length
    readonly property string model: Settings.magiModel

    FileView { id: promptFile; path: Quickshell.shellDir + "/data/magi-prompt.txt"; blockLoading: true }

    // back to the idle display
    function dismiss() {
        if (busy) return;
        question = "";
        votes = [];
        error = "";
    }

    function ask(q) {
        q = (q ?? "").trim();
        if (!q.length || busy) return;
        question = q;
        votes = [];
        error = "";
        busy = true;
        askedAt = Date.now();
        Sounds.play("toggle");
        const body = {
            model: model, stream: false, format: "json", keep_alive: 0,
            options: { num_predict: 220, temperature: 0.6 },
            prompt: promptFile.text().replace("QUESTION", q)
        };
        proc.command = ["curl", "-s", "-m", "180", "http://127.0.0.1:11434/api/generate", "-d", JSON.stringify(body)];
        proc.running = true;
    }

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: {
                root.busy = false;
                root.tookMs = Date.now() - root.askedAt;
                try {
                    const outer = JSON.parse(text);
                    if (outer.error) throw new Error(outer.error);
                    const a = JSON.parse(outer.response);
                    const one = (k, name) => {
                        const v = a[k] ?? a[k.toUpperCase()] ?? {};
                        return { name: name, reason: String(v.reason ?? "…").trim(), yes: /approve|yes|承認/i.test(String(v.vote ?? "")) };
                    };
                    root.votes = [one("casper", "CASPER · 3"), one("balthasar", "BALTHASAR · 2"), one("melchior", "MELCHIOR · 1")];
                    Sounds.play(root.approvals >= 2 ? "grant" : "deny", 0.5);
                } catch (e) {
                    root.error = text.length ? "MAGI OFFLINE · " + String(e.message ?? e).slice(0, 80) : "MAGI OFFLINE · is ollama running?";
                }
            }
        }
        onExited: code => { if (code !== 0 && root.busy) { root.busy = false; root.error = "MAGI OFFLINE · ollama did not answer"; } }
    }
}
