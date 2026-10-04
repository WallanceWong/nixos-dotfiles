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
    WlrLayershell.namespace: "whisper-cheatsheet"
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

    function category(b) {
        const a = b.arg, d = b.dispatcher;
        if (b.key.startsWith("XF86")) return "Media";
        if (/restart whisper-shell|hyprpaper/.test(a)) return "Rescue";
        if (/screenshot|annotate|picker|quickshell:record/.test(a)) return "Capture";
        if (["workspace", "movetoworkspace", "togglespecialworkspace"].includes(d)) return "Workspaces";
        if (["killactive", "togglefloating", "pseudo", "layoutmsg", "fullscreen", "movefocus", "movewindow"].includes(d)) return "Windows";
        if (d === "exec" && !/lock\.sh/.test(a)) return "Apps";
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
        radius: 7
        color: Theme.surface1
        border.width: 1
        border.color: Qt.alpha(Theme.lamp, 0.14)
        Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 2; radius: 7; color: Qt.alpha(Theme.crust, 0.5) }
        Text {
            id: chipText
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -1
            text: parent.text
            color: Theme.lamp
            font.family: Theme.font
            font.pixelSize: 12
            font.weight: Font.ExtraBold
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
            Icon { icon: group.icon; size: 18; color: Theme.teal; fill: 1 }
            Label { text: group.title; color: Theme.teal; font.pixelSize: 13; font.weight: Font.ExtraBold; font.letterSpacing: 0.6 }
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

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 1180)
        height: Math.min(parent.height - 80, content.implicitHeight + 56)
        radius: Theme.radius + 6
        color: Theme.glassStrong
        border.width: 1
        border.color: Theme.hairline
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
                Icon { icon: "keyboard"; size: 26; color: Theme.lamp; fill: 1 }
                Label { text: "keys"; font.pixelSize: 22; font.weight: Font.ExtraBold; color: Theme.lamp }
                Label { text: "the ones worth remembering"; color: Theme.subtext; font.pixelSize: 13 }
                Item { Layout.fillWidth: true }
                Rectangle {
                    implicitWidth: 240
                    implicitHeight: 34
                    radius: 17
                    color: Theme.surface0
                    border.width: 1
                    border.color: panel.filter ? Qt.alpha(Theme.lamp, 0.4) : Theme.hairline
                    Icon { anchors { left: parent.left; leftMargin: 11; verticalCenter: parent.verticalCenter } icon: "search"; size: 17; color: Theme.subtext }
                    Label {
                        anchors { left: parent.left; leftMargin: 36; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                        text: panel.filter || "type to filter"
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
