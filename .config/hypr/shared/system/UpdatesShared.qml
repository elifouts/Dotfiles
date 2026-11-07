pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int count: 0
    Process {
        id: checkProc
        command: ["sh", "-c", "checkupdates 2>/dev/null | wc -l"]
        stdout: StdioCollector { onStreamFinished: root.count = parseInt(text) || 0 }
    }
    function recount() {
        if (!checkProc.running) checkProc.running = true
    }
    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.recount()
    }
    FileView {
        path: "/var/log/pacman.log"
        watchChanges: true
        preload: false
        printErrors: false
        onFileChanged: pacmanRan.restart()
    }
    Timer { id: pacmanRan; interval: 3000; onTriggered: root.recount() }

    Process {
        id: updateProc
        command: ["kitty", "--title", "System update", "sh", "-c", "yay -Syu; echo; read -rp 'Done. Press enter to close.' _"]
        onExited: root.recount()
    }
    function run() {
        if (!updateProc.running) updateProc.running = true
    }
}
