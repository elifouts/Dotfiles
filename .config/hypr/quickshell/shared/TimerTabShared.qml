import QtQuick
import QtQuick.Shapes
import "../style/common"

Item {
    id: page

    property var timer

    function toTurns(s) { return s <= 60 ? s / 60 : s <= 3600 ? 1 + (s / 60 - 1) / 59 : 2 + (s / 60 - 60) / 420 }
    function fromTurns(u) {
        return Math.max(1, u < 1 ? Math.round(u * 60) : u < 2 ? 60 * (1 + Math.round((u - 1) * 59)) : 60 * (60 + 5 * Math.round((u - 2) * 84)))
    }
    function nudge(d) { if (!timer.running) timer.set(fromTurns(Math.max(0, Math.min(3, toTurns(timer.total) + d)))) }
    readonly property real turns: toTurns(timer.total)
    readonly property real lap: turns % 1 || (turns > 0 ? 1 : 0)
    readonly property real sweep: timer.active ? timer.frac : lap

    Item {
        id: dial
        width: 150
        height: 150
        anchors.centerIn: parent

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: Theme.alpha(Theme.fg, 0.1)
                strokeWidth: Theme.lines ? 3 : 7
                fillColor: "transparent"
                PathAngleArc { centerX: 75; centerY: 75; radiusX: 68; radiusY: 68; startAngle: 0; sweepAngle: 360 }
            }
            ShapePath {
                strokeColor: page.timer.running ? Theme.accent2 : Theme.alpha(Theme.caution, 0.7)
                strokeWidth: Theme.lines ? 3 : 7
                fillColor: "transparent"
                capStyle: Theme.round ? ShapePath.RoundCap : ShapePath.FlatCap
                PathAngleArc {
                    centerX: 75
                    centerY: 75
                    radiusX: 68
                    radiusY: 68
                    startAngle: -90
                    sweepAngle: 360 * page.sweep
                    Behavior on sweepAngle { enabled: !spin.pressed; NumberAnimation { duration: Theme.ms(300) } }
                }
            }
        }

        Rectangle {
            readonly property real a: (page.sweep * 360 - 90) * Math.PI / 180
            visible: !page.timer.running
            x: 75 + 68 * Math.cos(a) - width / 2
            y: 75 + 68 * Math.sin(a) - height / 2
            width: spin.pressed ? 16 : 13
            height: width
            radius: Theme.round * width / 2
            color: Theme.bright
            Behavior on width { NumberAnimation { duration: Theme.fast } }
        }

        Column {
            anchors.centerIn: parent
            spacing: 2
            LabelShared {
                anchors.horizontalCenter: parent.horizontalCenter
                text: page.timer.format(page.timer.remaining)
                font.pixelSize: 30
                font.bold: true
                color: Theme.bright
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 5
                Repeater {
                    model: 3
                    Rectangle {
                        required property int index
                        readonly property bool on: index === Math.min(2, Math.ceil(page.turns) - 1)
                        width: on ? 14 : 5
                        height: 5
                        radius: Theme.round * 2.5
                        color: on ? (page.timer.running ? Theme.accent2 : Theme.caution) : Theme.alpha(Theme.fg, 0.2)
                        Behavior on width { SettleShared { duration: Theme.fast } }
                        Behavior on color { ColorAnimation { duration: Theme.fast } }
                    }
                }
            }
        }

        MouseArea {
            id: spin
            property real last: 0
            property real u: 0
            anchors.fill: parent
            enabled: !page.timer.running
            cursorShape: Qt.PointingHandCursor
            function angle(m) { return Math.atan2(m.y - 75, m.x - 75) * 180 / Math.PI }
            onPressed: m => { last = angle(m); u = page.turns }
            onPositionChanged: m => {
                const a = angle(m)
                u = Math.max(0, Math.min(3, u + ((a - last + 540) % 360 - 180) / 360))
                last = a
                page.timer.set(page.fromTurns(u))
            }
            onWheel: w => page.nudge(w.angleDelta.y / 120 / 60)
        }
    }

    Button {
        anchors.right: dial.left
        anchors.rightMargin: 28
        anchors.verticalCenter: dial.verticalCenter
        width: 34
        height: 34
        label: "󰑓"
        onPressed: page.timer.reset()
    }
    Button {
        anchors.left: dial.right
        anchors.leftMargin: 28
        anchors.verticalCenter: dial.verticalCenter
        width: 34
        height: 34
        primary: true
        label: page.timer.running ? "󰏤" : "󰐊"
        onPressed: page.timer.toggle()
    }
}
