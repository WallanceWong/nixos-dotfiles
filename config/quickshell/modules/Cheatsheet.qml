import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.components

// Super + / — every keyboard shortcut, read live from Hyprland (the
// descriptions come from the bindd lines in hyprland.conf). Type to filter.
PanelWindow {
    id: panel

    readonly property bool open: Panels.open === "cheatsheet"
    screen: Panels.screen
    visible: open || veil.opacity > 0
    WlrLayershell.namespace: "eva-cheatsheet"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    property string filter: ""
    property var binds: []
    onOpenChanged: if (open) { filter = ""; reader.running = true; keys.forceActiveFocus(); }

    // shortcuts Hyprland doesn't know about
    readonly property var extras: [
        { mods: ["Ctrl"], keys: ["Space"], desc: "English / 中文", cat: "Shell" },
        { mods: [], keys: ["3-finger swipe ↑"], desc: "Workspace overview", cat: "Workspaces" },
        { mods: [], keys: ["3-finger swipe ↔"], desc: "Switch workspace", cat: "Workspaces" },
        { mods: ["Super"], keys: ["drag"], desc: "Move window", cat: "Windows" },
        { mods: ["Super"], keys: ["right-drag"], desc: "Resize window", cat: "Windows" }
    ]

    readonly property var keyNames: ({
        grave: "`", PERIOD: ".", SLASH: "/", COMMA: ",", ESCAPE: "Esc", SPACE: "Space", TAB: "Tab",
        left: "←", right: "→", up: "↑", down: "↓", mouse_down: "scroll ↓", mouse_up: "scroll ↑", Print: "PrtSc",
        XF86AudioRaiseVolume: "Vol +", XF86AudioLowerVolume: "Vol −", XF86AudioMute: "Mute", XF86AudioMicMute: "Mic mute",
        XF86MonBrightnessUp: "Bright +", XF86MonBrightnessDown: "Bright −", XF86AudioPlay: "Play", XF86AudioNext: "Next", XF86AudioPrev: "Prev"
    })

    function modsOf(mask) {
        const m = [];
        if (mask & 64) m.push("Super");
        if (mask & 4) m.push("Ctrl");
        if (mask & 8) m.push("Alt");
        if (mask & 1) m.push("Shift");
        return m;
    }

    // grouped by description: with the Lua config every dispatcher reads "__lua"
    function category(b) {
        const d = b.description;
        if (b.key.startsWith("XF86")) return "Media";
        if (/shell|Fallback|touchpad/i.test(d)) return "Rescue";
        if (/Screenshot|Record|Draw|colour/i.test(d)) return "Capture";
        if (/workspace|Drop-down|minimized/i.test(d)) return "Workspaces";
        if (/window|Float|Pseudo|split|Fullscreen|Minimize/i.test(d) && !/switcher/i.test(d)) return "Windows";
        if (/^(Terminal|Files|Code editor)/.test(d)) return "Apps";
        return "Shell";
    }

    // merge "Super+1 … Super+5" into one row, arrows likewise
    function build(list) {
        const rows = [];
        for (const b of list) {
            if (!b.has_description) continue;
            const mods = modsOf(b.modmask);
            const key = keyNames[b.key] ?? b.key;
            const prev = rows.find(r => r.desc === b.description && r.mods.join() === mods.join());
            if (prev) { if (!prev.keys.includes(key)) prev.keys.push(key); continue; }
            rows.push({ mods: mods, keys: [key], desc: b.description, cat: category(b) });
        }
        for (const r of rows) {
            if (r.keys.length > 2 && r.keys.every(k => /^\d$/.test(k))) r.keys = [r.keys[0] + "–" + r.keys[r.keys.length - 1]];
            else if (r.keys.length === 4 && r.keys.every(k => "←→↑↓".includes(k))) r.keys = ["arrows"];
        }
        // the one that ends the session goes last
        rows.sort((a, b) => (a.desc.startsWith("Log out") ? 1 : 0) - (b.desc.startsWith("Log out") ? 1 : 0));
        return rows.concat(extras);
    }

    Process {
        id: reader
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: { try { panel.binds = panel.build(JSON.parse(text)); } catch (e) { panel.binds = panel.extras; } }
        }
    }

    function shown(cat) {
        const f = filter.toLowerCase();
        return binds.filter(r => r.cat === cat && (!f || r.desc.toLowerCase().includes(f) || r.keys.join(" ").toLowerCase().includes(f) || r.mods.join(" ").toLowerCase().includes(f)));
    }

    Rectangle {
        id: veil
        anchors.fill: parent
        color: Qt.alpha(Theme.crust, 0.62)
        opacity: panel.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.normal; easing.type: Theme.easing } }
        MouseArea { anchors.fill: parent; onClicked: Panels.close() }
    }

    Item {
        id: keys
        focus: panel.open
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape) { if (panel.filter) panel.filter = ""; else Panels.close(); }
            else if (e.key === Qt.Key_Backspace) panel.filter = panel.filter.slice(0, -1);
            else if (e.text.length && e.text.charCodeAt(0) >= 32 && !(e.modifiers & (Qt.ControlModifier | Qt.MetaModifier))) panel.filter += e.text;
            e.accepted = true;
        }
    }

    component Chip: Rectangle {
        property string text
        implicitWidth: Math.max(26, chipText.implicitWidth + 14)
        implicitHeight: 24
        radius: 0
        color: Theme.surface1
        border.width: 1
        border.color: Qt.alpha(Theme.accent, 0.14)
        Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 2; radius: 0; color: Qt.alpha(Theme.crust, 0.5) }
        Text {
            id: chipText
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -1
            text: parent.text
            color: Theme.accent
            font.family: Theme.mono
            font.pixelSize: 11
            font.weight: Font.Bold
        }
    }

    component Group: ColumnLayout {
        id: group
        property string title
        property string icon
        readonly property var rows: panel.shown(title)
        visible: rows.length > 0
        Layout.fillWidth: true
        spacing: 7
        RowLayout {
            spacing: 8
            Layout.bottomMargin: 2
            Icon { icon: group.icon; size: 18; color: Theme.armour; fill: 1 }
            Caps { text: group.title; color: Theme.armour; font.pixelSize: 13; font.weight: Font.Bold; font.letterSpacing: 2.5 }
        }
        Repeater {
            model: group.rows
            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 5
                Label { Layout.fillWidth: true; text: modelData.desc; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                Repeater {
                    model: modelData.mods
                    RowLayout {
                        required property var modelData
                        spacing: 5
                        Chip { text: modelData }
                        Text { text: "+"; color: Theme.overlay; font.pixelSize: 11 }
                    }
                }
                Repeater {
                    model: modelData.keys
                    RowLayout {
                        required property var modelData
                        required property int index
                        spacing: 5
                        Text { visible: index > 0; text: "/"; color: Theme.overlay; font.pixelSize: 11 }
                        Chip { text: modelData }
                    }
                }
            }
        }
        Item { Layout.preferredHeight: 10 }
    }

    Item {
        id: card
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 1180)
        height: Math.min(parent.height - 80, content.implicitHeight + 56)
        HudFrame {
            anchors.fill: parent
            fill: Theme.glassStrong
            stroke: Qt.alpha(Theme.accent, 0.5)
            cut: 24
            ticks: true
        }
        Rectangle { x: 36; y: 0; width: 160; height: 3; color: Theme.accent }
        opacity: veil.opacity
        scale: 0.96 + 0.04 * veil.opacity
        clip: true
        MouseArea { anchors.fill: parent }   // clicks inside don't close

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 28 }
            spacing: 18

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Text { text: "操縦"; font.family: Theme.title; font.weight: Font.Black; font.pixelSize: 30; color: Theme.text }
                Caps { text: "CONTROL REFERENCE"; font.pixelSize: 16; font.weight: Font.Bold; font.letterSpacing: 4; color: Theme.accent }
                Item { Layout.fillWidth: true }
                Rectangle {
                    implicitWidth: 240
                    implicitHeight: 34
                    radius: 0
                    color: Theme.surface0
                    border.width: 1
                    border.color: panel.filter ? Qt.alpha(Theme.accent, 0.4) : Theme.hairline
                    Icon { anchors { left: parent.left; leftMargin: 11; verticalCenter: parent.verticalCenter } icon: "search"; size: 17; color: Theme.subtext }
                    Label {
                        anchors { left: parent.left; leftMargin: 36; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                        text: panel.filter || "TYPE TO FILTER"
                        color: panel.filter ? Theme.text : Theme.overlay
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 40
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    spacing: 0
                    Group { title: "Shell"; icon: "auto_awesome" }
                    Group { title: "Apps"; icon: "apps" }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    spacing: 0
                    Group { title: "Windows"; icon: "select_window" }
                    Group { title: "Workspaces"; icon: "view_carousel" }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    spacing: 0
                    Group { title: "Capture"; icon: "screenshot_region" }
                    Group { title: "Media"; icon: "music_note" }
                    Group { title: "Rescue"; icon: "healing" }
                }
            }
        }
    }
}
