import QtQuick

Row {
    id: wave
    property bool playing: false
    property int bars: 10
    property var tint: null
    property real barWidth: 2.5
    property real reach: 12
    spacing: barWidth < 3 ? 2 : barWidth * 0.6

    onPlayingChanged: Cava.users += playing ? 1 : -1
    Component.onCompleted: if (playing) Cava.users++
    Component.onDestruction: if (playing) Cava.users--

    Repeater {
        model: wave.bars
        Rectangle {
            required property int index
            readonly property real level: wave.playing ? (Cava.levels[index] || 0) : 0
            anchors.verticalCenter: parent.verticalCenter
            width: wave.barWidth
            radius: wave.barWidth / 2
            height: Math.max(4, Math.round((3 + level * wave.reach) / 2) * 2)
            color: wave.tint ? wave.tint(index / (wave.bars - 1)) : Theme.accent
            opacity: wave.playing ? 0.35 + 0.65 * level : 0.45
        }
    }
}
