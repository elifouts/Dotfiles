import QtQuick

Item {
    id: pb

    property var player: null
    property real size: 36
    readonly property bool playing: Media.playing(player)

    width: size
    height: size

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.soft(Theme.accent, area.containsMouse)
        scale: area.pressed ? 0.9 : (area.containsMouse ? 1.05 : 1)
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        Behavior on scale { NumberAnimation { duration: Theme.ms(220); easing.type: Easing.OutBack; easing.overshoot: 2.4 } }

        PlayPause {
            anchors.centerIn: parent
            width: Math.round(pb.size * 0.36)
            height: width
            color: Theme.ink
            m: pb.playing ? 1 : 0
            Behavior on m { Settle { duration: Theme.ms(220) } }
        }
    }

    Hover {
        id: area
        anchors.fill: parent
        onClicked: Media.toggle(pb.player)
    }
}
