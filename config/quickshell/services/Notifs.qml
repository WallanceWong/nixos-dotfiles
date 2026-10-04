pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification daemon: popups for live notifications, a plain-data history
// for the control centre, Do Not Disturb, and the soft chime.
Singleton {
    id: root

    readonly property var live: server.trackedNotifications.values
    readonly property ListModel history: ListModel {}
    property int unread: 0

    function iconFor(n) {
        if (n.image) return n.image;
        if (n.appIcon) return Theme.icon(n.appIcon, "dialog-information");
        const entry = DesktopEntries.heuristicLookup(n.desktopEntry || n.appName);
        return Theme.icon(entry?.icon ?? "dialog-information", "dialog-information");
    }

    function clearHistory() { history.clear(); unread = 0; }
    function dismissAll() { for (const n of live.slice()) n.dismiss(); }

    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: n => {
            const critical = n.urgency === NotificationUrgency.Critical;
            root.history.insert(0, {
                appName: n.appName || "notification",
                summary: n.summary,
                body: n.body,
                icon: n.appIcon ? Theme.icon(n.appIcon, "dialog-information") : root.iconFor(n),
                time: Date.now()
            });
            if (root.history.count > 60) root.history.remove(60, root.history.count - 60);
            root.unread++;

            if (Settings.dnd && !critical) return;   // recorded, but no popup
            n.tracked = true;
            Sounds.play("notify", critical ? 0.7 : 0.5);
        }
    }
}
