import QtQuick
import Quickshell
import Quickshell.Io
import "bar"
import "bar/island"
import "bar/menus"
import "common"
import "launcher"
import "music"
import "settings"

ShellRoot {
    id: root

    Process {
        running: true
        command: ["sh", "-c", "for f in */shell.qml; do [ -f \"$f\" ] && echo \"${f%/shell.qml}\"; done"]
        workingDirectory: Quickshell.shellDir + "/style"
        stdout: StdioCollector {
            onStreamFinished: root.load(text.split("\n").filter(s => s !== ""))
        }
    }

    function load(shells) {
        for (let i = 0; i < shells.length; i++) {
            const c = Qt.createComponent(shells[i] + "/shell.qml");
            if (c.status === Component.Error)
                console.warn("utilities:", shells[i], c.errorString());
            else
                c.createObject(root);
        }
    }
}
