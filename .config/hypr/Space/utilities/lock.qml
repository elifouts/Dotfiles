import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import "common"
import "lock"

// own process so it still comes up if the shell is dead
ShellRoot {
    id: root

    readonly property bool preview: Quickshell.env("LOCK_PREVIEW") === "1"
    property string pw: ""
    property bool checking: false
    // bumps on a wrong password so every screen shakes
    property int wrong: 0
    property real t: 0
    Component.onCompleted: fadeIn.start()
    NumberAnimation { id: fadeIn; target: root; property: "t"; to: 1; duration: 700; easing.type: Easing.OutCubic }

    function submit() {
        if (checking || !pw) return
        checking = true
        pam.start()
    }
    PamContext {
        id: pam
        // pam file is in shared/system/
        configDirectory: Hypr.dir + "/shared/system/pam"
        config: "password.conf"
        user: Quickshell.env("USER")
        onPamMessage: if (responseRequired) respond(root.pw)
        onCompleted: result => {
            root.checking = false
            if (result === PamResult.Success) return leave.start()
            root.pw = ""
            root.wrong++
        }
    }
    SequentialAnimation {
        id: leave
        NumberAnimation { target: root; property: "t"; to: 0; duration: 350; easing.type: Easing.InCubic }
        ScriptAction { script: { session.locked = false; Qt.quit() } }
    }

    WlSessionLock {
        id: session
        locked: !root.preview
        WlSessionLockSurface {
            color: "black"
            LockScreen { anchors.fill: parent; lock: root }
        }
    }

    Variants {
        model: root.preview ? Quickshell.screens : []
        FloatingWindow {
            required property var modelData
            title: "Lock preview"
            implicitWidth: Math.round(modelData.width * 0.6)
            implicitHeight: Math.round(modelData.height * 0.6)
            color: "black"
            LockScreen { anchors.fill: parent; lock: root }
        }
    }
}
