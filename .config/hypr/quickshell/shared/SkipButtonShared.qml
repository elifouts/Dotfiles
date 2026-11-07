import QtQuick
import "../style/common"

Item {
    id: btn

    property var player: null
    property int dir: 1
    property real size: 40
    property real glyphSize: Math.round(size * 0.38)
    property color tint: Theme.fg
    readonly property bool dimmed: !player || !(dir > 0 ? player.canGoNext : player.canGoPrevious)
    property real kick: 0

    width: size
    height: size

    Connections {
        target: MediaShared
        function onSkipped(p, d) { if (p === btn.player && d === btn.dir) kickAnim.restart() }
    }

    SequentialAnimation {
        id: kickAnim
        NumberAnimation { target: btn; property: "kick"; to: 1; duration: Theme.ms(80); easing.type: Easing.OutQuad }
        NumberAnimation { target: btn; property: "kick"; to: 0; duration: Theme.ms(340); easing.type: Easing.OutBack; easing.overshoot: 2.2 }
    }

    LabelShared {
        anchors.centerIn: parent
        text: btn.dir > 0 ? "" : ""
        font.pixelSize: btn.glyphSize
        color: btn.dimmed ? Theme.dim : (area.containsMouse ? Theme.accent2 : btn.tint)
        opacity: btn.dimmed ? 0.5 : 1
        scale: area.pressed ? 0.84 : 1
        transform: Translate { x: btn.dir * btn.kick * btn.size * 0.14 }
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        Behavior on scale { NumberAnimation { duration: Theme.ms(180); easing.type: Easing.OutBack; easing.overshoot: 2 } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: btn.dimmed ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: if (!btn.dimmed) MediaShared.skip(btn.player, btn.dir)
    }
}
