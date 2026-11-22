import QtQuick
import Quickshell
import qs.services

// The lock screen: the Eva-01 screen at boot and in the UNIT-01 setup, the
// MAGI vote in NERV HQ. Typing goes straight to Locker (no text field, so no
// input method can get in the way); the views only draw.
Item {
    id: root

    property var screen: null
    property bool live: true
    // the UI rests after a while; any key or mouse movement wakes it
    property bool awake: true
    property bool entered: false

    focus: true
    Component.onCompleted: { forceActiveFocus(); entered = true; }

    Timer { id: rest; interval: 14000; running: root.awake && Locker.typed.length === 0 && !Locker.busy; onTriggered: root.awake = false }
    function wake() { awake = true; rest.restart(); }
    Connections {
        target: Locker
        function onTyping() { root.wake(); }
        function onGrantedChanged() { if (Locker.granted) Sounds.play("grant", 0.55); }
        function onFailed() { root.wake(); view.item.shakes++; Sounds.play(Theme.drama && !Locker.boot ? "alarm" : "deny", 0.6); }
    }

    Keys.onPressed: event => {
        wake();
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) Locker.submit();
        else if (event.key === Qt.Key_Backspace) (event.modifiers & Qt.ControlModifier) ? Locker.clear() : Locker.backspace();
        else if (event.key === Qt.Key_Escape) Locker.clear();
        else if (event.text.length > 0 && event.text.charCodeAt(0) >= 32 && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) { Locker.key(event.text); Sounds.tick(); }
        event.accepted = true;
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: root.wake()
        onClicked: { root.wake(); root.forceActiveFocus(); }
    }

    Loader {
        id: view
        anchors.fill: parent
        sourceComponent: Theme.magi && !Locker.boot ? magi : eva01
    }
    Component {
        id: eva01
        Eva01Lock { screen: root.screen; live: root.live; awake: root.awake; entered: root.entered }
    }
    Component {
        id: magi
        MagiLock { screen: root.screen; live: root.live; awake: root.awake; entered: root.entered }
    }
}
