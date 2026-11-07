import QtQuick
import Quickshell
import Quickshell.Io
import "../../shared"
import "../common"

ShellRoot {
    NotificationPopupsShared { hidden: NotifsShared.quiet }

    IpcHandler {
        target: "notifications"
        function clear(): void { NotifsShared.clearAll() }
        function toggleDnd(): void { NotifsShared.dnd = !NotifsShared.dnd }
    }
}
