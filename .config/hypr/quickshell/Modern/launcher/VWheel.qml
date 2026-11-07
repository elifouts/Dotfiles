import QtQuick
import "../../shared"
import "../common"

Item {
    id: wheel

    property var entries: []
    property int cur: 0
    property bool animate: true
    property real pos: 0
    signal activated(int index)

    property real centerFrac: 0.36
    readonly property int n: entries.length
    readonly property real pitch: Math.min(64, Math.max(46, height / 6.2))
    readonly property real rowH: Math.round(pitch * 0.74)
    readonly property int reach: 5

    property real t: 0
    NumberAnimation on t {
        from: 0
        to: Math.PI * 2
        duration: 3200
        loops: Animation.Infinite
        running: wheel.animate && wheel.visible && wheel.n > 0
    }

    property real intro: 1
    NumberAnimation { id: introAnim; target: wheel; property: "intro"; from: 0; to: 1; duration: Theme.ms(420); easing.type: Easing.OutCubic }

    function reset() {
        settle.stop()
        cur = 0
        pos = 0
        introAnim.restart()
    }

    function step(d) {
        if (n === 0) return
        const next = Math.max(0, Math.min(n - 1, cur + d))
        if (next === cur) return
        cur = next
        settle.stop()
        settle.to = cur
        settle.start()
    }

    NumberAnimation { id: settle; target: wheel; property: "pos"; duration: Theme.ms(380); easing.type: Easing.OutCubic }

    property real wheelAcc: 0
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: event => {
            wheel.wheelAcc += event.angleDelta.y
            while (Math.abs(wheel.wheelAcc) >= 120) {
                wheel.step(wheel.wheelAcc > 0 ? -1 : 1)
                wheel.wheelAcc -= wheel.wheelAcc > 0 ? 120 : -120
            }
        }
    }

    Item {
        id: stage
        anchors.fill: parent
        clip: true

        Repeater {
            model: wheel.reach * 2 + 1

            Item {
                id: row
                required property int index
                readonly property int idx: Math.round(wheel.pos) - wheel.reach + index
                readonly property bool live: idx >= 0 && idx < wheel.n
                readonly property var e: live ? wheel.entries[idx] : null
                readonly property real d: idx - wheel.pos
                readonly property real ad: Math.abs(d)
                readonly property real lift: Math.max(0, 1 - ad)
                readonly property real ease: lift * lift * (3 - 2 * lift)

                visible: live && ad < 4.4
                width: stage.width - 24
                height: wheel.rowH
                x: (stage.width - width) / 2
                y: stage.height * wheel.centerFrac - height / 2 + d * wheel.pitch * (1 - 0.05 * Math.min(ad, 3)) + (1 - wheel.intro) * 18 * (1 + Math.min(ad, 3))
                   + Math.sin(wheel.t) * 1.2 * ease
                scale: Math.max(0.7, 1 - 0.08 * ad)
                opacity: Math.max(0, 1 - 0.27 * ad) * Math.min(1, wheel.intro * (1.6 - 0.12 * Math.min(ad, 4)))
                z: 10 - ad

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.r(10) + 2 * row.ease
                    color: Theme.alpha(Theme.along([Theme.fg, Theme.soft(Theme.accent)], row.ease), 0.045 + 0.795 * row.ease)
                }

                LabelShared {
                    id: name
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, parent.width * 0.55)
                    elide: Text.ElideRight
                    text: row.e ? row.e.n : ""
                    font.pixelSize: 15
                    color: Theme.along([Theme.fg, Theme.ink], row.ease)
                }

                LabelShared {
                    anchors.left: name.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideLeft
                    text: !row.e ? "" : row.e.k === "alias" ? "= " + row.e.d : row.e.k === "function" ? "function" : row.e.d
                    font.pixelSize: 11
                    color: Theme.alpha(Theme.along([Theme.fg, Theme.ink], row.ease), 0.5 + 0.5 * row.ease)
                    opacity: 0.55 + 0.45 * row.ease
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (row.idx === wheel.cur) wheel.activated(row.idx)
                        else wheel.step(row.idx - wheel.cur)
                    }
                }
            }
        }
    }
}
