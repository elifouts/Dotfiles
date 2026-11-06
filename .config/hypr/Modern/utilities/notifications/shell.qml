import QtQuick
import Quickshell
import Quickshell.Io
import "../common"

ShellRoot {
    NotificationPopups { hidden: Notifs.quiet }

    IpcHandler {
        target: "notifications"
        function clear(): void { Notifs.clearAll() }
        function toggleDnd(): void { Notifs.dnd = !Notifs.dnd }
    }
}
