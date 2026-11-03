import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    readonly property var standalone: ["boot", "lock"]

    Process {
        running: true
        command: ["sh", "-c", "for f in */shell.qml; do [ -f \"$f\" ] && echo \"${f%/shell.qml}\"; done"]
        workingDirectory: Quickshell.shellDir
        stdout: StdioCollector {
            onStreamFinished: root.load(text.split("\n").filter(s => s !== "" && !root.standalone.includes(s)))
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
