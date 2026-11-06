import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import "common"
import "land"

ShellRoot {
    id: root

    component LockScreen: Item {
        id: face

        required property var lock
        readonly property real t: lock.t

        SystemClock { id: clock; precision: SystemClock.Minutes }

        Terrain { anchors.fill: parent; layer.enabled: true }
        Rectangle { anchors.fill: parent; color: Theme.void_; opacity: 0.35 + 0.3 * face.t }

        Item {
            anchors.fill: parent
            opacity: face.t
            scale: 1.06 - 0.06 * face.t

            Column {
                anchors.centerIn: parent
                spacing: 10
                transform: Translate { id: shake }

                Hud {
                    caps: false
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatTime(clock.date, Store.values["space.clock24"] === false ? "h:mm" : "HH:mm")
                    font.pixelSize: Math.min(face.width, face.height) * 0.11
                    font.weight: Font.ExtraLight
                    font.letterSpacing: 6
                    color: Theme.fg
                }
                Hud {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(clock.date, "dddd  ·  dd MMMM")
                }
                Item { width: 1; height: 26 }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 300
                    height: 34
                    color: Theme.alpha(Theme.bg, 0.45)
                    border.width: 1
                    border.color: face.lock.wrong && !input.text ? Theme.warn : input.activeFocus ? Theme.accent : Theme.faint
                    Rectangle { width: 2; height: parent.height; color: Theme.accent }
                    TextInput {
                        id: input
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        font.family: Theme.font
                        font.pixelSize: 14
                        font.letterSpacing: 3
                        color: Theme.fg
                        focus: true
                        enabled: !face.lock.checking
                        onTextChanged: face.lock.pw = text
                        onAccepted: face.lock.submit()
                        Keys.onEscapePressed: text = ""
                        Component.onCompleted: forceActiveFocus()
                    }
                    Hud {
                        x: 14
                        height: parent.height
                        visible: !input.text
                        text: face.lock.checking ? "checking" : face.lock.wrong ? "wrong password" : "password"
                        color: face.lock.wrong ? Theme.warn : Theme.alpha(Theme.fg, 0.3)
                    }
                    MouseArea { anchors.fill: parent; onClicked: input.forceActiveFocus() }
                }
                Hud {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Quickshell.env("USER")
                    color: Theme.alpha(Theme.fg, 0.3)
                }
            }
        }

        Connections {
            target: face.lock
            function onWrongChanged() { input.text = ""; shakeAnim.restart() }
        }
        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: shake; property: "x"; to: -12; duration: 50 }
            NumberAnimation { target: shake; property: "x"; to: 8; duration: 70 }
            NumberAnimation { target: shake; property: "x"; to: 0; duration: 80 }
        }
    }

    readonly property bool preview: Quickshell.env("LOCK_PREVIEW") === "1"
    property string pw: ""
    property bool checking: false
    property int wrong: 0
    property real t: 0
    Component.onCompleted: fadeIn.start()
    Settle { id: fadeIn; target: root; property: "t"; to: 1; duration: Theme.ms(700) }

    function submit() {
        if (checking || !pw) return
        checking = true
        pam.start()
    }
    PamContext {
        id: pam
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
        Settle { target: root; property: "t"; to: 0; duration: Theme.ms(350); easing.bezierCurve: Theme.leave }
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
