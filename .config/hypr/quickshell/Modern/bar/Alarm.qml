import QtQuick
import Quickshell
import Quickshell.Io
import "../../shared"
import "../common"

Item {
    id: al

    property bool open: false
    property string length: ""
    readonly property bool holdOpen: open
    signal done()

    implicitHeight: 40

    Process {
        running: al.open
        command: ["ffplay", "-nodisp", "-loop", "5", "-loglevel", "quiet", Quickshell.shellPath("style/bar/alarm.ogg")]
        onExited: if (al.open) al.done()
    }

    LabelShared {
        id: bell
        x: 4
        anchors.verticalCenter: parent.verticalCenter
        text: "󰀠"
        font.pixelSize: 24
        color: Theme.accent
        transform: Translate { id: hop }

        NumberAnimation on scale { from: 0.3; to: 1; duration: Theme.ms(520); easing.type: Easing.OutBack; easing.overshoot: 2.4 }

        ParallelAnimation {
            running: al.open && Theme.animates
            loops: Animation.Infinite
            onStopped: { hop.y = 0; bell.rotation = 0 }
            SequentialAnimation {
                NumberAnimation { target: hop; property: "y"; to: -5; duration: 180; easing.type: Easing.OutQuad }
                NumberAnimation { target: hop; property: "y"; to: 0; duration: 420; easing.type: Easing.OutBounce }
                PauseAnimation { duration: 350 }
            }
            SequentialAnimation {
                SequentialAnimation {
                    loops: 4
                    NumberAnimation { target: bell; property: "rotation"; to: 12; duration: 60; easing.type: Easing.InOutSine }
                    NumberAnimation { target: bell; property: "rotation"; to: -12; duration: 60; easing.type: Easing.InOutSine }
                }
                NumberAnimation { target: bell; property: "rotation"; to: 0; duration: 120; easing.type: Easing.OutQuad }
                PauseAnimation { duration: 350 }
            }
        }
    }

    Column {
        anchors.left: bell.right
        anchors.leftMargin: 12
        anchors.right: xbtn.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        LabelShared { text: "Time's up"; font.pixelSize: 14; color: Theme.bright }
        LabelShared {
            width: parent.width
            text: "Your " + al.length + " session has finished."
            font.pixelSize: 11
            color: Theme.dim
            elide: Text.ElideRight
        }
    }

    Button {
        id: xbtn
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 28
        height: 28
        label: "󰅖"
        onPressed: al.done()
    }
}
