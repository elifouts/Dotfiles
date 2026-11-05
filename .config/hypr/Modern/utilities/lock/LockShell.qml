import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../common"

ShellRoot {
    id: root

    property bool captured: false
    property bool released: false
    Process {
        running: !root.captured
        command: ["sh", "-c", 'until [ -e "$0/.done" ]; do sleep 0.005; done', Lock.shots]
        onExited: root.captured = true
    }
    Timer { running: true; interval: 300; onTriggered: root.captured = true }

    WlSessionLock {
        id: lock
        locked: root.captured && !Lock.preview
        onSecureChanged: if (secure) Lock.enter()

        WlSessionLockSurface {
            color: "transparent"
            Face {
                anchors.fill: parent
                screenName: screen ? screen.name : ""
            }
        }
    }

    Variants {
        model: !Lock.preview && (Lock.t === 1 || Lock.leaving) ? Quickshell.screens : []
        PanelWindow {
            required property var modelData
            screen: modelData
            visible: !root.released
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "lock-handoff"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region {}

            Backdrop {
                anchors.fill: parent
                source: Lock.wallpaper
            }
        }
    }

    Variants {
        model: Lock.preview && root.captured ? Quickshell.screens : []
        FloatingWindow {
            required property var modelData
            title: "Lock preview"
            implicitWidth: Math.round(modelData.width * 0.7)
            implicitHeight: Math.round(modelData.height * 0.7)
            color: "transparent"
            Face {
                anchors.fill: parent
                screenName: modelData.name
            }
            Component.onCompleted: startTimer.restart()
        }
    }

    Timer { id: startTimer; interval: 40; onTriggered: Lock.enter() }

    Connections {
        target: Lock
        function onUnlock() { lock.locked = false; root.released = true }
        function onFinish() { Qt.quit() }
    }
}
