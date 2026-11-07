import QtQuick
import "../../shared"
import "../common"

Item {
    id: viz

    property bool running: false
    property real intro: 1
    readonly property int bars: CavaShared.bars

    readonly property real gap: Math.max(2, Math.round(width / bars * 0.32))
    readonly property real barW: (width - gap * (bars - 1)) / bars

    property bool ready: false
    property real live: 0
    property real phase: 0

    NumberAnimation on phase {
        running: viz.running && viz.live < 1
        from: 0
        to: Math.PI * 2
        duration: 1100
        loops: Animation.Infinite
    }
    NumberAnimation {
        id: liveAnim
        target: viz
        property: "live"
        from: 0
        to: 1
        duration: Theme.ms(700)
        easing.type: Easing.InOutQuad
    }

    function dist(i) { return Math.abs(i - (bars - 1) / 2) / ((bars - 1) / 2) }
    function sweep(p, i) { return Math.max(0, Math.min(1, (p - 0.55 * dist(i)) / 0.45)) }
    function backOut(x) { const c = 2.2; return 1 + (c + 1) * Math.pow(x - 1, 3) + c * Math.pow(x - 1, 2) }

    onRunningChanged: { CavaShared.users += running ? 1 : -1; if (!running) { ready = false; liveAnim.stop(); live = 0 } }
    Component.onCompleted: if (running) CavaShared.users++
    Component.onDestruction: if (running) CavaShared.users--
    Connections {
        target: CavaShared
        function onLevelsChanged() { if (viz.running && !viz.ready && CavaShared.levels.length) { viz.ready = true; liveAnim.restart() } }
    }

    Repeater {
        model: viz.bars

        Rectangle {
            id: bar
            required property int index
            readonly property real pop: viz.backOut(viz.sweep(viz.intro, index))
            readonly property real handoff: viz.sweep(viz.live, index)
            readonly property real ripple: 0.12 + 0.18 * (0.5 + 0.5 * Math.sin(viz.phase - viz.dist(index) * Math.PI * 2))
            readonly property real level: ripple * (1 - handoff) + (CavaShared.levels[index] || 0) * handoff
            x: index * (viz.barW + viz.gap)
            anchors.bottom: parent.bottom
            width: viz.barW
            height: Math.max(viz.barW, viz.height * level) * Math.max(0, pop)
            radius: viz.barW / 2
            color: Theme.along(Theme.spectrum, index / (viz.bars - 1))
            opacity: (0.35 + 0.6 * Math.min(1, level * 1.6)) * Math.min(1, viz.sweep(viz.intro, index) * 3)
            Behavior on height { enabled: bar.handoff >= 1; NumberAnimation { duration: Theme.ms(90); easing.type: Easing.OutQuad } }
        }
    }
}
