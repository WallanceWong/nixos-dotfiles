pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

// The lock screen's brain: locked or not, what has been typed, and the PAM
// conversation that checks it (the "hyprlock" PAM service, so the keyring
// unlocks too). A flag file in the runtime dir remembers the lock, so a shell
// that crashes or restarts while locked comes back locked.
Singleton {
    id: root

    property bool locked: false
    property string typed: ""
    property bool busy: false
    property bool unlocking: false      // the short fade between "yes" and gone
    property string message: ""
    property int fails: 0
    property int unreadAtLock: 0
    property double lockedAt: 0
    // the lock right after autologin (lock.sh login): always the Eva-01 screen,
    // whichever setup is active
    property bool boot: false
    // how long the "yes" lingers before the screen goes (the MAGI vote takes longer)
    property int unlockDelay: 320
    property bool granted: false        // PAM said yes; the view is playing its exit
    signal failed()
    signal typing()

    readonly property string flag: Quickshell.env("EVA_LOCK_FLAG") || ((Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/eva-locked")

    function lock(atBoot) {
        if (locked) return;
        boot = !!atBoot;
        granted = false;
        typed = "";
        message = "";
        fails = 0;
        unreadAtLock = Notifs.unread;
        lockedAt = Date.now();
        Panels.close();
        locked = true;
        Quickshell.execDetached(["sh", "-c", "echo " + (boot ? "boot" : "lock") + " > \"$0\"", flag]);
        // type the password in English, whatever the input method was doing
        Quickshell.execDetached(["sh", "-c", "command -v fcitx5-remote >/dev/null && fcitx5-remote -c"]);
    }

    function unlock() {
        locked = false;
        unlocking = false;
        granted = false;
        boot = false;
        typed = "";
        busy = false;
        message = "";
        Quickshell.execDetached(["rm", "-f", flag]);
    }

    function key(text) {
        if (busy) return;
        typed += text;
        message = "";
        typing();
    }
    function backspace() { if (!busy) { typed = typed.slice(0, -1); typing(); } }
    function clear() { if (!busy) { typed = ""; typing(); } }

    function submit() {
        if (busy || typed.length === 0) return;
        busy = true;
        message = "";
        if (!pam.start()) { busy = false; message = "couldn't ask PAM"; }
    }

    PamContext {
        id: pam
        config: Quickshell.env("EVA_PAM") || "hyprlock"
        onPamMessage: {
            if (responseRequired) respond(root.typed);
            else if (messageIsError) root.message = message;
        }
        onCompleted: result => {
            root.busy = false;
            if (result === PamResult.Success) {
                root.granted = true;
                exitDelay.restart();
            } else {
                root.typed = "";
                root.fails++;
                root.message = root.fails > 2 ? "ACCESS DENIED · " + root.fails + " ATTEMPTS" : "ACCESS DENIED";
                root.failed();
            }
        }
        onError: err => {
            root.busy = false;
            root.typed = "";
            root.message = "PAM: " + PamError.toString(err);
            root.failed();
        }
    }

    Timer { id: exitDelay; interval: Math.max(0, root.unlockDelay - 320); onTriggered: { root.unlocking = true; fadeOut.restart(); } }
    Timer { id: fadeOut; interval: 320; onTriggered: root.unlock() }

    // locked before this shell started (login, or a restart while locked)?
    // The flag says which: "boot" (autologin) or "lock".
    Process {
        running: true
        command: ["cat", root.flag]
        stdout: StdioCollector { id: flagText }
        onExited: code => { if (code === 0) root.lock(flagText.text.trim() === "boot"); }
    }
}
