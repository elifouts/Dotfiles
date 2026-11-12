import QtQuick
import "../style/common"

Item {
    id: sk

    property var player: null
    property real u: 1
    property bool active: true

    function px(v) { return Math.round(v * u) }
    function clock(s) {
        if (!(s > 0)) return "0:00"
        s = Math.floor(s)
        const m = Math.floor(s / 60), r = s % 60
        return m >= 60 ? Math.floor(m / 60) + ":" + String(m % 60).padStart(2, "0") + ":" + String(r).padStart(2, "0")
            : m + ":" + String(r).padStart(2, "0")
    }

    readonly property real length: player && player.lengthSupported ? player.length : 0
    readonly property real position: player && player.positionSupported ? player.position : 0
    readonly property bool live: length > 0 && !!player && player.canSeek
    readonly property bool playing: MediaShared.playing(player)
    property bool seeking: false
    property real seekFrac: 0
    readonly property real frac: seeking ? seekFrac : (length > 0 ? Math.max(0, Math.min(1, position / length)) : 0)
    readonly property bool hot: bar.containsMouse || bar.pressed

    height: px(36)

    Timer {
        running: sk.active && sk.visible && sk.playing
        interval: 33
        repeat: true
        onTriggered: if (sk.player) sk.player.positionChanged()
    }

    Item {
        width: parent.width
        height: sk.px(14)

        Rectangle {
            id: groove
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: sk.hot ? sk.px(6) : sk.px(4)
            radius: height / 2
            color: Theme.alpha(Theme.fg, 0.14)
            Behavior on height { NumberAnimation { duration: Theme.ms(200); easing.type: Easing.OutCubic } }

            Rectangle {
                height: parent.height
                radius: parent.radius
                width: Math.max(height, parent.width * sk.frac)
                color: Theme.accent2
                Behavior on width {
                    enabled: !sk.seeking && !sk.playing
                    NumberAnimation { duration: Theme.ms(160); easing.type: Easing.OutCubic }
                }
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: groove.width * sk.frac - width / 2
            width: sk.px(14)
            height: width
            radius: width / 2
            color: Theme.bright
            scale: sk.hot && sk.live ? (bar.pressed ? 1.15 : 1) : 0
            Behavior on scale { NumberAnimation { duration: Theme.ms(240); easing.type: Easing.OutBack; easing.overshoot: 2 } }
        }

        HoverShared {
            id: bar
            anchors.fill: parent
            anchors.margins: -sk.px(6)
            enabled: sk.live
            preventStealing: true

            function fracAt(mouse) {
                return Math.max(0, Math.min(1, (mouse.x - sk.px(6)) / groove.width))
            }
            onPressed: mouse => { sk.seekFrac = fracAt(mouse); sk.seeking = true }
            onPositionChanged: mouse => { if (pressed) sk.seekFrac = fracAt(mouse) }
            onReleased: {
                if (sk.player && sk.player.canSeek) sk.player.position = sk.seekFrac * sk.length
                sk.seeking = false
            }
        }
    }

    LabelShared {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        text: sk.clock(sk.frac * sk.length)
        font.pixelSize: sk.px(11)
        color: sk.seeking ? Theme.bright : Theme.dim
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }
    LabelShared {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        text: sk.length > 0 ? sk.clock(sk.length) : "--:--"
        font.pixelSize: sk.px(11)
        color: Theme.dim
    }
}
