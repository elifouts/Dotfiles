import QtQuick
import "../style/common"

Item {
    id: pb

    property var player: null
    property real size: 36
    readonly property bool playing: MediaShared.playing(player)

    width: size
    height: size

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.soft(Theme.accent, area.containsMouse)
        scale: area.pressed ? 0.9 : (area.containsMouse ? 1.05 : 1)
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        Behavior on scale { NumberAnimation { duration: Theme.ms(220); easing.type: Easing.OutBack; easing.overshoot: 2.4 } }

        PlayPauseShared {
            anchors.centerIn: parent
            width: Math.round(pb.size * 0.36)
            height: width
            color: Theme.ink
            m: pb.playing ? 1 : 0
            Behavior on m { SettleShared { duration: Theme.ms(220) } }
        }
    }

    HoverShared {
        id: area
        anchors.fill: parent
        onClicked: MediaShared.toggle(pb.player)
    }
}
