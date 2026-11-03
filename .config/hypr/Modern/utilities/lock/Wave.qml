import QtQuick
import "../common"

// same visualizer as the bar
Row {
    id: wave

    property bool playing: false
    property real u: 1
    readonly property int bars: 10
    readonly property var levels: feed.levels

    spacing: 2 * u

    CavaFeed { id: feed; running: wave.playing; bars: wave.bars; framerate: 60 }

    Repeater {
        model: wave.bars

        Rectangle {
            required property int index
            readonly property real level: wave.playing ? (wave.levels[index] || 0) : 0

            anchors.verticalCenter: parent.verticalCenter
            width: 2.5 * wave.u
            // even pixel heights so it doesn't flicker
            height: Math.max(4, Math.round((3 + level * 12) * wave.u / 2) * 2)
            radius: width / 2
            color: Theme.along(Theme.spectrum, index / (wave.bars - 1))
            opacity: wave.playing ? 0.35 + 0.65 * level : 0.45

            Behavior on height { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
            Behavior on opacity { NumberAnimation { duration: 100 } }
        }
    }
}
