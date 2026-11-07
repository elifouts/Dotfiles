import QtQuick
import "../../shared"
import "../common"

Item {
    id: page

    property var counts: ({})
    property real intro: 1
    signal run(string id, string cmd, bool afterClose)

    readonly property string util: HyprShared.util + "/"
    readonly property var commands: [
        { id: "lock", icon: "", label: "Lock", sub: "Lock the session", cmd: PowerShared.cmd("lock") },
        { id: "suspend", icon: "", label: "Suspend", sub: "Sleep the machine", cmd: PowerShared.cmd("suspend") },
        { id: "logout", icon: "", label: "Log out", sub: "End the Hyprland session", confirm: "log out", cmd: PowerShared.cmd("logout") },
        { id: "reboot", icon: "", label: "Reboot", sub: "Restart the machine", confirm: "reboot", cmd: PowerShared.cmd("reboot") },
        { id: "poweroff", icon: "", label: "Power off", sub: "Shut down", confirm: "power off", cmd: PowerShared.cmd("poweroff") },
        { id: "screenshot", icon: "", label: "Screenshot", sub: "Select a region", after: true, cmd: "hyprshot -m region -o ~/Screenshots/" },
        { id: "home", icon: "", label: "Home", sub: "Home screen", after: true, cmd: util + "session/shells.sh home" },
        { id: "wallpaper", icon: "", label: "Wallpaper", sub: "Pick a wallpaper", after: true, cmd: util + "session/shells.sh wallpaper" },
        { id: "settings", icon: "", label: "Settings", sub: "Hyprland settings", after: true, cmd: util + "session/shells.sh settings" }
    ]
    readonly property var pinned: ["home", "settings", "wallpaper"]
    readonly property var entries: pinned.map(id => commands.find(c => c.id === id)).concat(commands
        .filter(c => !pinned.includes(c.id))
        .map((c, i) => ({ c: c, i: i, n: counts[c.id] || 0 }))
        .sort((a, b) => b.n - a.n || a.i - b.i)
        .map(x => x.c))

    property int current: 0
    property int armed: -1
    readonly property var cur: entries[Math.min(current, entries.length - 1)]
    readonly property bool waiting: armed === current

    onCurrentChanged: if (armed !== current) armed = -1

    function reset() {
        current = 0
        armed = -1
    }

    function activate(i) {
        const c = entries[i]
        current = i
        if (c.confirm && armed !== i) { armed = i; return }
        armed = -1
        page.run(c.id, c.cmd, !!c.after)
    }

    function handleKey(event) {
        const k = event.key
        if (k === Qt.Key_Right || k === Qt.Key_Down || k === Qt.Key_L || k === Qt.Key_J) current = ring.mod(current + 1)
        else if (k === Qt.Key_Left || k === Qt.Key_Up || k === Qt.Key_H || k === Qt.Key_K) current = ring.mod(current - 1)
        else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) activate(current)
        else return false
        return true
    }

    function cancel() {
        if (armed < 0) return false
        armed = -1
        return true
    }

    Radial {
        id: ring
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width
        btn: Math.round(width * 0.14)
        entries: page.entries
        current: page.current
        intro: page.intro
        tint: page.waiting ? Theme.warn : Theme.accent
        onPicked: i => page.current = i
        onActivated: i => page.activate(i)

        Column {
            anchors.centerIn: parent
            width: parent.width
            spacing: 6

            LabelShared {
                anchors.horizontalCenter: parent.horizontalCenter
                text: page.cur.icon
                font.pixelSize: Math.round(ring.btn * 0.62)
                color: page.waiting ? Theme.warn : Theme.accent
                Behavior on color { ColorAnimation { duration: Theme.fast } }
            }
            LabelShared {
                anchors.horizontalCenter: parent.horizontalCenter
                text: page.cur.label
                font.pixelSize: 17
                color: Theme.bright
            }
            LabelShared {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: page.waiting ? "Press again to " + page.cur.confirm : page.cur.sub
                font.pixelSize: 11
                color: page.waiting ? Theme.warn : Theme.dim
            }
        }
    }
}
