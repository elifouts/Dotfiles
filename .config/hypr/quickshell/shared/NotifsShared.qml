pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool dnd: false
    onDndChanged: {
        Quickshell.execDetached(["sh", "-c", "echo " + (dnd ? 1 : 0) + " > \"${XDG_RUNTIME_DIR:-/tmp}/home-dnd\""])
        save()
    }
    property bool quiet: false
    property var popups: []
    property var arrived: ({})
    property var saved: []
    property bool ready: false
    readonly property var notifs: server.trackedNotifications.values.filter(n => !n.transient).reverse().concat(saved)
    onNotifsChanged: save()
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
        saved = []
        popups = []
    }

    function save() {
        if (!ready) return
        store.setText(JSON.stringify({
            dnd: dnd,
            notifs: notifs.filter(n => !n.transient).map(n => ({
                id: n.id,
                summary: n.summary,
                body: n.body,
                appName: n.appName,
                appIcon: n.appIcon,
                desktopEntry: n.desktopEntry,
                image: n.image.startsWith("image:") ? "" : n.image,
                urgency: n.urgency,
                arrived: arrived[n.id] ?? Date.now()
            }))
        }))
    }
    function load() {
        let data = null
        try { data = JSON.parse(store.text()) } catch (e) {}
        if (data) {
            dnd = data.dnd
            saved = data.notifs.filter(s => kept.fresh || typeof s.id === "string").map((s, i) => {
                s.id = "saved-" + i
                s.actions = []
                s.dismiss = () => forget(s)
                arrived[s.id] = s.arrived
                return s
            })
        }
        ready = true
    }
    function forget(s) {
        delete arrived[s.id]
        saved = saved.filter(x => x !== s)
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

    FileView {
        id: store
        path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/notifications.json"
        blockLoading: true
        blockWrites: true
        printErrors: false
    }

    PersistentProperties {
        id: kept
        reloadableId: "notifs"
        property bool fresh: true
        onLoaded: {
            root.load()
            fresh = false
        }
    }
}
