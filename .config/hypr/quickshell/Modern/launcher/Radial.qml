import QtQuick
import "../../shared"
import "../common"

Item {
    id: ring

    property var entries: []
    property int current: 0
    property real btn: 46
    property real radius: Math.min(width, height) / 2 - btn / 2 - 2
    property real intro: 1
    property color tint: Theme.accent
    signal picked(int index)
    signal activated(int index)
    default property alias center: hub.data
    readonly property real hubSize: 2 * (radius - btn / 2) - 14

    readonly property int n: entries.length
    function mod(i) { return n > 0 ? ((i % n) + n) % n : 0 }
    function angle(p) { return -Math.PI / 2 + p * 2 * Math.PI / Math.max(1, n) }

    property real pos: current
    onCurrentChanged: {
        let d = mod(current - mod(Math.round(pos)))
        if (d > n / 2) d -= n
        glide.stop()
        glide.to = Math.round(pos) + d
        glide.start()
    }
    SettleShared { id: glide; target: ring; property: "pos"; duration: Theme.ms(320) }

    function local(i) {
        const s = 0.35
        const e = Math.max(0, Math.min(1, (intro - s * i / Math.max(1, n)) / (1 - s)))
        return 1 - Math.pow(1 - e, 3)
    }

    property bool moved: false
    onIntroChanged: if (intro === 0) moved = false
    HoverHandler {
        onPointChanged: if (ring.intro >= 1) ring.moved = true
    }

    property real wheelAcc: 0
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: event => {
            ring.wheelAcc += event.angleDelta.y
            while (Math.abs(ring.wheelAcc) >= 120) {
                ring.picked(ring.mod(ring.current + (ring.wheelAcc > 0 ? -1 : 1)))
                ring.wheelAcc -= ring.wheelAcc > 0 ? 120 : -120
            }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: ring.radius * 2 * ring.local(0)
        height: width
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: Theme.alpha(Theme.fg, 0.08)
    }

    Rectangle {
        width: ring.btn + 8
        height: width
        radius: width / 2
        x: ring.width / 2 + Math.cos(ring.angle(ring.pos)) * ring.radius * ring.local(0) - width / 2
        y: ring.height / 2 + Math.sin(ring.angle(ring.pos)) * ring.radius * ring.local(0) - height / 2
        color: Theme.soft(ring.tint)
        opacity: ring.n > 0 ? ring.local(0) : 0
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }

    Repeater {
        model: ring.entries

        Item {
            id: b
            required property var modelData
            required property int index
            readonly property bool on: ring.current === index
            readonly property real e: ring.local(index)
            width: ring.btn
            height: ring.btn
            x: ring.width / 2 + Math.cos(ring.angle(index)) * ring.radius * e - width / 2
            y: ring.height / 2 + Math.sin(ring.angle(index)) * ring.radius * e - height / 2
            opacity: e
            scale: 0.6 + 0.4 * e

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Theme.alpha(Theme.fg, b.on ? 0 : (area.containsMouse ? 0.12 : 0.06))
                Behavior on color { ColorAnimation { duration: Theme.fast } }
            }

            LabelShared {
                anchors.centerIn: parent
                text: b.modelData.icon
                font.pixelSize: Math.round(ring.btn * 0.36)
                scale: b.on ? 1.14 : 1
                color: b.on ? Theme.on(ring.tint) : area.containsMouse ? Theme.bright : Theme.fg
                Behavior on scale { NumberAnimation { duration: Theme.ms(260); easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: Theme.fast } }
            }

            HoverShared {
                id: area
                anchors.fill: parent
                onEntered: if (ring.moved) ring.picked(b.index)
                onPositionChanged: if (ring.moved && !b.on) ring.picked(b.index)
                onClicked: ring.activated(b.index)
            }
        }
    }

    Item {
        id: hub
        anchors.centerIn: parent
        width: ring.hubSize
        height: ring.hubSize
        opacity: ring.local(0)
        scale: 0.9 + 0.1 * ring.local(0)
    }
}
