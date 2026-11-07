import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    IpcHandler {
        target: "home"
        function toggle(): void {
            if (home.item) home.item.toggle()
            else open()
        }
        function open(): void {
            home.active = true
            home.item.show()
        }
        function close(): void { if (home.item) home.item.close() }
    }

    LazyLoader {
        id: home
        source: "Home.qml"
    }
    Connections {
        target: home.item
        function onDone() { home.active = false }
    }
}
