import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.services
import qs.components

// One search box for everything: apps, "=" calculator, clipboard history,
// emoji and open windows.
PanelWindow {
    id: panel

    readonly property bool open: Panels.open === "launcher"
    readonly property string mode: Panels.launcherMode
    screen: Panels.screen
    visible: open || box.opacity > 0
    WlrLayershell.namespace: "whisper-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: 640
    implicitHeight: 560
    color: "transparent"

    HyprlandFocusGrab { active: panel.open; windows: [panel]; onCleared: Panels.close() }

    onOpenChanged: {
        if (open) {
            search.text = "";
            list.currentIndex = 0;
            search.forceActiveFocus();
            if (mode === "clipboard") clipProc.running = true;
            if (mode === "windows") Hyprland.refreshToplevels();
        }
    }
    onModeChanged: if (open) { search.text = ""; if (mode === "clipboard") clipProc.running = true; }

    // ── data sources ──
    property var clips: []
    Process {
        id: clipProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: panel.clips = text.split("\n").filter(l => l.length).slice(0, 200).map(l => {
                const tab = l.indexOf("\t");
                return { id: l.slice(0, tab), text: l.slice(tab + 1) };
            })
        }
    }
    FileView { id: emojiFile; path: Quickshell.shellDir + "/data/emoji.json"; blockLoading: true }
    readonly property var emoji: { try { return JSON.parse(emojiFile.text()); } catch (e) { return []; } }

    function fuzzy(q, s) {
        if (!s) return -1;
        q = q.toLowerCase(); s = s.toLowerCase();
        if (!q.length) return 1;
        if (s.startsWith(q)) return 100 - s.length * 0.05;
        const i = s.indexOf(" " + q);
        if (i >= 0) return 85 - i * 0.1;
        const j = s.indexOf(q);
        if (j >= 0) return 70 - j * 0.2;
        let k = 0, gaps = 0, last = -1;
        for (let c = 0; c < s.length && k < q.length; c++) {
            if (s[c] === q[k]) { if (last >= 0) gaps += c - last - 1; last = c; k++; }
        }
        return k === q.length ? 40 - gaps : -1;
    }

    function calc(expr) {
        const e = expr.replace(/\s+/g, "").replace(/×/g, "*").replace(/÷/g, "/").replace(/\^/g, "**");
        if (!/^[0-9+\-*/().%e]+$/.test(e) || !/[0-9]/.test(e)) return null;
        try {
            const v = Function("return (" + e + ")")();
            return typeof v === "number" && isFinite(v) ? Math.round(v * 1e10) / 1e10 : null;
        } catch (err) { return null; }
    }

    readonly property var results: {
        const q = search.text.trim();
        if (mode === "apps" && q.startsWith("=")) {
            const v = calc(q.slice(1));
            return v === null ? [{ icon: "calculate", glyph: true, name: "type a sum, e.g. =12*7", desc: "calculator", run: () => {} }]
                              : [{ icon: "calculate", glyph: true, name: String(v), desc: "= " + q.slice(1) + "   ·   Enter copies", run: () => Quickshell.execDetached(["wl-copy", String(v)]) }];
        }
        if (mode === "apps") {
            const counts = Settings.launchCounts;
            const out = [];
            for (const a of DesktopEntries.applications.values) {
                if (a.noDisplay) continue;
                const s = Math.max(fuzzy(q, a.name), fuzzy(q, a.genericName) * 0.8, fuzzy(q, Array.isArray(a.keywords) ? a.keywords.join(" ") : String(a.keywords ?? "")) * 0.6, fuzzy(q, a.id) * 0.5);
                if (s < 0) continue;
                out.push({ entry: a, score: s + Math.min(25, (counts[a.id] ?? 0) * 2.5), icon: a.icon, name: a.name, desc: a.comment || a.genericName || "",
                           run: () => { Settings.bumpLaunch(a.id); Desktop.launchEntry(a); } });
            }
            out.sort((x, y) => y.score - x.score || x.name.localeCompare(y.name));
            const v = q.length > 1 ? calc(q) : null;
            if (v !== null && /[+\-*/^%]/.test(q)) out.unshift({ icon: "calculate", glyph: true, name: String(v), desc: q + "   ·   Enter copies", run: () => Quickshell.execDetached(["wl-copy", String(v)]) });
            return out.slice(0, 60);
        }
        if (mode === "clipboard") {
            return clips.map(c => ({ c: c, s: fuzzy(q, c.text) })).filter(x => x.s >= 0).slice(0, 80).map(x => ({
                icon: x.c.text.startsWith("[[ binary") ? "image" : "content_paste", glyph: true, name: x.c.text, desc: "",
                run: () => Quickshell.execDetached(["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", x.c.id])
            }));
        }
        if (mode === "emoji") {
            // empty search: natural order (smileys first); otherwise best match first
            const hits = emoji.map((e, i) => ({ e: e, i: i, s: q.length ? fuzzy(q, e[1]) : 1 })).filter(x => x.s >= 0);
            if (q.length) hits.sort((a, b) => b.s - a.s || a.i - b.i);
            return hits.slice(0, 80).map(x => ({
                emoji: x.e[0], name: x.e[1], desc: "", run: () => Quickshell.execDetached(["wl-copy", x.e[0]])
            }));
        }
        if (mode === "windows") {
            return Hyprland.toplevels.values.map(t => {
                const cls = t.lastIpcObject?.class ?? "";
                const entry = DesktopEntries.heuristicLookup(cls);
                return { t: t, s: Math.max(fuzzy(q, t.title), fuzzy(q, cls)), icon: entry?.icon ?? "application-x-executable",
                         name: t.title, desc: (entry?.name ?? cls) + "  ·  workspace " + (t.workspace?.id ?? "?"),
                         run: () => Hyprland.dispatch("focuswindow address:" + (t.lastIpcObject?.address ?? ("0x" + t.address))) };
            }).filter(x => x.s >= 0).sort((a, b) => b.s - a.s);
        }
        return [];
    }

    function activate(i) {
        const r = results[i];
        if (!r) return;
        Panels.close();
        r.run();
    }

    Rectangle {
        id: box
        anchors.fill: parent
        radius: Theme.radius + 8
        color: Theme.glassStrong
        border.width: 1
        border.color: Qt.alpha(Theme.lamp, 0.35)
        opacity: panel.open ? 1 : 0
        scale: panel.open ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: Theme.normal; easing.type: Theme.easing } }
        Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Theme.easing } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // search field
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 52
                radius: 26
                color: Theme.surface0
                border.width: 1
                border.color: search.activeFocus ? Qt.alpha(Theme.lamp, 0.5) : Theme.hairline
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 10
                    spacing: 12
                    Icon {
                        icon: panel.mode === "clipboard" ? "content_paste" : panel.mode === "emoji" ? "mood" : panel.mode === "windows" ? "select_window" : "bedtime"
                        size: 22; fill: 1; color: Theme.lamp; rotation: panel.mode === "apps" ? -20 : 0
                    }
                    TextField {
                        id: search
                        Layout.fillWidth: true
                        background: null
                        color: Theme.text
                        placeholderTextColor: Theme.overlay
                        placeholderText: panel.mode === "clipboard" ? "search the clipboard…" : panel.mode === "emoji" ? "find an emoji (copies it)…" : panel.mode === "windows" ? "switch to a window…" : "where to tonight?   (= for maths)"
                        font.family: Theme.font
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                        selectByMouse: true
                        onTextChanged: list.currentIndex = 0
                        Keys.onEscapePressed: Panels.close()
                        Keys.onDownPressed: list.incrementCurrentIndex()
                        Keys.onUpPressed: list.decrementCurrentIndex()
                        Keys.onReturnPressed: panel.activate(list.currentIndex)
                        Keys.onEnterPressed: panel.activate(list.currentIndex)
                        Keys.onTabPressed: {
                            const modes = ["apps", "windows", "clipboard", "emoji"];
                            Panels.launcherMode = modes[(modes.indexOf(panel.mode) + 1) % modes.length];
                        }
                        Keys.onPressed: e => {
                            if (e.key === Qt.Key_PageDown) { list.currentIndex = Math.min(list.count - 1, list.currentIndex + 8); e.accepted = true; }
                            else if (e.key === Qt.Key_PageUp) { list.currentIndex = Math.max(0, list.currentIndex - 8); e.accepted = true; }
                        }
                    }
                    // mode chips
                    Row {
                        spacing: 2
                        Repeater {
                            model: [["apps", "apps"], ["windows", "select_window"], ["clipboard", "content_paste"], ["emoji", "mood"]]
                            IconButton {
                                required property var modelData
                                icon: modelData[1]
                                iconSize: 17
                                implicitWidth: 32
                                implicitHeight: 32
                                active: panel.mode === modelData[0]
                                onClicked: { Panels.launcherMode = modelData[0]; search.forceActiveFocus(); }
                            }
                        }
                    }
                }
            }

            // results
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 3
                model: panel.results
                highlightMoveDuration: Theme.fast
                boundsBehavior: Flickable.StopAtBounds
                highlight: Rectangle { radius: Theme.radiusSmall + 2; color: Theme.surface1; border.width: 1; border.color: Qt.alpha(Theme.lamp, 0.25) }

                delegate: Item {
                    id: item
                    required property var modelData
                    required property int index
                    readonly property bool current: ListView.isCurrentItem
                    width: list.width
                    height: 52

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 14
                        Item {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            IconImage {
                                anchors.fill: parent
                                visible: !item.modelData.glyph && !item.modelData.emoji
                                source: visible ? Theme.icon(item.modelData.icon ?? "", "application-x-executable") : ""
                                asynchronous: true
                            }
                            Icon { anchors.centerIn: parent; visible: !!item.modelData.glyph; icon: item.modelData.icon ?? ""; size: 22; color: Theme.teal }
                            Text { anchors.centerIn: parent; visible: !!item.modelData.emoji; text: item.modelData.emoji ?? ""; font.pixelSize: 24 }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Label { Layout.fillWidth: true; text: item.modelData.name; font.pixelSize: 14; color: item.current ? Theme.lamp : Theme.text; maximumLineCount: 1 }
                            Label { Layout.fillWidth: true; visible: text.length > 0; text: item.modelData.desc ?? ""; font.pixelSize: 11; font.weight: Font.Medium; color: Theme.subtext }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: list.currentIndex = item.index
                        onClicked: panel.activate(item.index)
                    }
                }

                Column {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    spacing: 6
                    Icon { anchors.horizontalCenter: parent.horizontalCenter; icon: "nights_stay"; size: 36; color: Theme.overlay }
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: panel.mode === "clipboard" ? "the clipboard is empty" : "nothing out here"; color: Theme.overlay }
                }
            }

            Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: "↑↓ choose   ·   Enter open   ·   Tab switch mode   ·   Esc close"
                font.pixelSize: 11
                color: Theme.overlay
            }
        }
    }
}
