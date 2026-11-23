pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The MAGI are three sides of you, the way Naoko Akagi's were three sides of
// her: MELCHIOR-1 THE BUILDER, BALTHASAR-2 ME, CASPER-3 THE BOY. A question
// asked on the NERV HQ wallpaper (components/MagiScene.qml) goes to a local
// model (Ollama: nothing leaves the laptop) with a prompt built from your
// profile, ~/.config/magi-profile/{builder,me,boy}.json (private, not in this
// repo; edit them and the next question uses the change). Each side answers
// APPROVE / CONDITIONAL / REJECT with a reason, and the votes arrive one by one
// as the model writes them. The model is loaded when you click the question
// line and unloaded as soon as it has answered.
Singleton {
    id: root

    readonly property var sides: ["builder", "me", "boy"]
    property string question: ""
    property bool busy: false
    property string error: ""
    property var votes: ({})            // { builder: { verdict, reason, condition }, … } as they arrive
    property double askedAt: 0
    property double tookMs: 0
    property string buffer: ""
    readonly property int count: sides.filter(s => votes[s]).length
    readonly property bool done: !busy && count === 3
    readonly property int approvals: sides.filter(s => votes[s] && votes[s].verdict !== "REJECT").length
    readonly property bool conditional: sides.some(s => votes[s] && votes[s].verdict === "CONDITIONAL")
    readonly property string resolution: approvals >= 2 ? (conditional ? "APPROVED · CONDITIONAL" : "APPROVED") : "REJECTED"
    readonly property string model: Settings.magiModel
    readonly property string dir: Quickshell.env("HOME") + "/.config/magi-profile/"
    readonly property string api: "http://127.0.0.1:11434/api/generate"
    // the answer needs ~1,000 tokens; Ollama's global window (16k, for OpenClaw) would cost ~1 GB more
    readonly property var options: ({ num_ctx: 2048, num_predict: 220, temperature: 0.7 })

    FileView { id: builderFile; path: root.dir + "builder.json"; blockLoading: true; watchChanges: true; onFileChanged: reload() }
    FileView { id: meFile; path: root.dir + "me.json"; blockLoading: true; watchChanges: true; onFileChanged: reload() }
    FileView { id: boyFile; path: root.dir + "boy.json"; blockLoading: true; watchChanges: true; onFileChanged: reload() }

    // one side, condensed: a small model reads ~25 tokens a second on this CPU,
    // so the prompt keeps only the core, top priorities, the verdict rules and three examples
    function side(name, p) {
        const lc = s => String(s ?? "").toLowerCase();
        const j = p.judges_by ?? {};
        const pri = (p.priorities ?? []).slice(0, 3).map(x => String(x).replace(/^\d+\.\s*/, "")).join("; ");
        const ex = (p.example_decisions ?? []).slice(0, 3).map(e => `  "${e.scenario}" -> ${e.verdict}: ${lc(e.reason)}`).join("\n");
        return `${name}: ${p.core}\n  cares most about: ${pri}\n`
             + `  APPROVE if ${lc(j.APPROVE)}; CONDITIONAL if ${lc(j.CONDITIONAL)}; REJECT if ${lc(j.REJECT)}.\n${ex}`;
    }
    function prompt(q) {
        const p = [builderFile, meFile, boyFile].map(f => JSON.parse(f.text()));
        const power = Math.round(Stats.battery * 100) + "%" + (Stats.onBattery ? " on battery" : " charging");
        return `You are the MAGI of ${Settings.magiName}. Like Naoko Akagi's MAGI, you are three sides of one person. `
             + "Each side judges the question by its own rules.\n\n"
             + side("BUILDER", p[0]) + "\n\n" + side("ME", p[1]) + "\n\n" + side("BOY", p[2]) + "\n\n"
             + "Rules: each reason is first person, lowercase, under 12 words, in that side's own voice. "
             + "The sides often disagree. The verdict must follow from the reason. "
             + "condition is what must be true first (only for CONDITIONAL, else empty).\n"
             + `Now: ${Qt.formatDateTime(new Date(), "dddd HH:mm")}, laptop battery ${power}.\nQuestion: ${q}`;
    }
    // the answer's shape is forced, so the votes always parse
    readonly property var schema: {
        const unit = { type: "object", required: ["reason", "verdict", "condition"], properties: {
            reason: { type: "string", maxLength: 80 },
            verdict: { type: "string", enum: ["APPROVE", "CONDITIONAL", "REJECT"] },
            condition: { type: "string", maxLength: 60 } } };
        return { type: "object", required: sides, properties: { builder: unit, me: unit, boy: unit } };
    }

    // clicking the question line loads the model while you type (same window size
    // as the question, or Ollama would load it twice); it drops after 2 minutes unused
    property double warmedAt: 0
    function warm() {
        if (busy || Date.now() - warmedAt < 60000) return;
        warmedAt = Date.now();
        warmProc.command = ["curl", "-s", "-m", "60", api, "-d", JSON.stringify({ model: model, keep_alive: "2m", options: options })];
        warmProc.running = true;
    }
    Process { id: warmProc }

    // back to the idle display
    function dismiss() {
        if (busy) return;
        question = "";
        votes = {};
        error = "";
    }

    function ask(q) {
        q = (q ?? "").trim();
        if (!q.length || busy) return;
        question = q;
        votes = {};
        error = "";
        buffer = "";
        let text;
        try { text = prompt(q); }
        catch (e) { error = "MAGI OFFLINE · no profile in ~/.config/magi-profile"; return; }
        busy = true;
        askedAt = Date.now();
        Sounds.play("toggle");
        const body = { model: model, stream: true, think: false, format: schema, keep_alive: 0, options: options, prompt: text };
        proc.command = ["curl", "-sN", "-m", "240", api, "-d", JSON.stringify(body)];
        proc.running = true;
    }

    // pick each side's vote out of the answer as soon as its part is complete
    function collect() {
        const next = Object.assign({}, votes);
        let found = false;
        for (const s of sides) {
            if (next[s]) continue;
            const m = buffer.match(new RegExp('"' + s + '"\\s*:\\s*(\\{[^{}]*\\})'));
            if (!m) continue;
            try {
                const v = JSON.parse(m[1]);
                next[s] = { verdict: String(v.verdict ?? "REJECT"), reason: String(v.reason ?? "…").trim(), condition: String(v.condition ?? "").trim() };
                found = true;
            } catch (e) {}
        }
        if (found) { votes = next; Sounds.play("toggle", 0.4); }
    }

    Process {
        id: proc
        stdout: SplitParser {
            onRead: line => {
                let d;
                try { d = JSON.parse(line); } catch (e) { return; }
                if (d.error) { root.error = "MAGI OFFLINE · " + String(d.error).slice(0, 80); return; }
                root.buffer += d.response ?? "";
                root.collect();
            }
        }
        onExited: code => {
            root.busy = false;
            root.tookMs = Date.now() - root.askedAt;
            if (root.count < 3) {
                if (!root.error.length) root.error = code === 7 ? "MAGI OFFLINE · is ollama running?" : "MAGI OFFLINE · the answer was cut short";
                return;
            }
            Sounds.play(root.approvals >= 2 ? "grant" : "deny", 0.5);
            // asked and switched away: say so when the MAGI have decided
            if (!Desktop.skyVisible)
                Quickshell.execDetached(["notify-send", "-a", "MAGI", "-i", "dialog-information", "MAGI · " + root.resolution, root.question]);
        }
    }
}
