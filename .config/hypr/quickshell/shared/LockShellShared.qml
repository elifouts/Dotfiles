import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../style/common"

ShellRoot {
    id: root

    Component.onCompleted: StoreShared.refresh()

    property bool captured: false
    property bool released: false
    Process {
        running: !root.captured
        command: ["sh", "-c", 'until [ -e "$0/.done" ]; do sleep 0.005; done', LockShared.shots]
        onExited: root.captured = true
    }
    Timer { running: true; interval: 300; onTriggered: root.captured = true }

    WlSessionLock {
        id: lock
        locked: root.captured && !LockShared.preview
        onSecureChanged: if (secure) LockShared.enter()

        WlSessionLockSurface {
            color: "transparent"
            LockFaceShared {
                anchors.fill: parent
                screenName: screen ? screen.name : ""
            }
        }
    }

    Variants {
        model: !LockShared.preview && (LockShared.t === 1 || LockShared.leaving) ? Quickshell.screens : []
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
                source: LockShared.wallpaper
            }
        }
    }

    Variants {
        model: LockShared.preview && root.captured ? Quickshell.screens : []
        FloatingWindow {
            required property var modelData
            title: "Lock preview"
            implicitWidth: Math.round(modelData.width * 0.7)
            implicitHeight: Math.round(modelData.height * 0.7)
            color: "transparent"
            LockFaceShared {
                anchors.fill: parent
                screenName: modelData.name
            }
            Component.onCompleted: startTimer.restart()
        }
    }

    Timer { id: startTimer; interval: 40; onTriggered: LockShared.enter() }

    Connections {
        target: LockShared
        function onUnlock() { lock.locked = false; root.released = true }
        function onFinish() { Qt.quit() }
    }
}
