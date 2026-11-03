pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// the notification daemon both styles use. styles only draw popups and the list
Singleton {
    id: root

    property bool dnd: false
    onDndChanged: Quickshell.execDetached(["sh", "-c", "echo " + (dnd ? 1 : 0) + " > \"${XDG_RUNTIME_DIR:-/tmp}/home-dnd\""])
    // a style sets this while it's already showing the full list, popups would just double up
    property bool quiet: false
    property var popups: []
    property var arrived: ({})
    readonly property var notifs: server.trackedNotifications.values.slice().reverse()
    readonly property int count: notifs.length

    function received(n) {
        n.tracked = true
        arrived[n.id] = Date.now()
        n.closed.connect(() => {
            hidePopup(n)
            delete arrived[n.id]
        })
        if (quiet || (dnd && n.urgency !== NotificationUrgency.Critical)) {
            if (n.transient) n.expire()
            return
        }
        popups = [n].concat(popups.filter(p => p !== n)).slice(0, 5)
    }
    function hidePopup(n) { popups = popups.filter(p => p !== n) }
    function expirePopup(n) {
        if (n.transient) n.expire()
        else hidePopup(n)
    }
    function clearAll() {
        for (const n of server.trackedNotifications.values.slice()) n.dismiss()
        popups = []
    }

    function iconFor(n) {
        if (n.image !== "") return n.image
        if (n.appIcon !== "") {
            if (n.appIcon.startsWith("/")) return "file://" + encodeURI(n.appIcon)
            const p = Quickshell.iconPath(n.appIcon, true)
            if (p !== "") return p
        }
        return n.desktopEntry !== "" ? Quickshell.iconPath(n.desktopEntry, true) : ""
    }
    // now is passed in so the caller's clock keeps it ticking
    function ago(n, now) {
        const s = Math.max(0, (now.getTime() - (arrived[n.id] ?? Date.now())) / 1000)
        if (s < 60) return "now"
        if (s < 3600) return Math.floor(s / 60) + "m ago"
        if (s < 86400) return Math.floor(s / 3600) + "h ago"
        return Math.floor(s / 86400) + "d ago"
    }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true
        onNotification: n => root.received(n)
    }
}
