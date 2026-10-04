import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// The lock screen (ext-session-lock): one LockView per screen.
// WHISPER_LOCK_PREVIEW=1 shows it as an ordinary overlay instead, for testing
// without locking anything.
Scope {
    WlSessionLock {
        locked: Locker.locked && Quickshell.env("WHISPER_LOCK_PREVIEW") !== "1"

        WlSessionLockSurface {
            id: surface
            color: Theme.crust
            LockView { anchors.fill: parent; screen: surface.screen }
        }
    }

    LazyLoader {
        active: Quickshell.env("WHISPER_LOCK_PREVIEW") === "1" && Locker.locked
        PanelWindow {
            screen: Panels.screen
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "whisper-lock-preview"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: Theme.crust
            LockView { anchors.fill: parent; screen: Panels.screen }
        }
    }
}
