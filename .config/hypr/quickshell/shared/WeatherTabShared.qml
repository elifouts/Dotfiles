import QtQuick
import "../style/common"

Item {
    id: wt

    property var weather

    Column {
        id: now
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(150, feels.implicitWidth)
        spacing: 4

        Row {
            spacing: 10
            LabelShared {
                anchors.verticalCenter: parent.verticalCenter
                text: wt.weather.ready ? wt.weather.glyph(wt.weather.code, wt.weather.night) : "󰖕"
                font.pixelSize: 38
                color: wt.weather.night ? Theme.accent2 : Theme.caution
            }
            LabelShared {
                anchors.verticalCenter: parent.verticalCenter
                text: wt.weather.ready ? wt.weather.temp + "°" : "--"
                font.pixelSize: 34
                font.bold: true
                color: Theme.bright
            }
        }
        LabelShared {
            width: parent.width
            text: wt.weather.ready ? wt.weather.desc : wt.weather.failed ? "Weather unavailable" : "Loading weather..."
            elide: Text.ElideRight
            font.pixelSize: 13
            font.capitalization: Theme.caps
            font.letterSpacing: Theme.tracking
            color: Theme.fg
        }
        LabelShared {
            id: feels
            visible: wt.weather.ready
            text: "Feels " + wt.weather.feels + "°  ·  H " + wt.weather.high + "°  L " + wt.weather.low + "°"
            font.pixelSize: 10
            font.capitalization: Theme.caps
            font.letterSpacing: Theme.tracking
            color: Theme.dim
        }
        Row {
            visible: wt.weather.ready
            spacing: 10
            Text { text: "󰖎 " + wt.weather.humidity + "%"; font.family: Theme.sans; font.pixelSize: 10; font.letterSpacing: Theme.tracking; color: Theme.dim }
            Text { text: "󰖝 " + wt.weather.wind + " mph"; font.family: Theme.sans; font.pixelSize: 10; font.letterSpacing: Theme.tracking; color: Theme.dim }
        }
        LabelShared {
            width: parent.width
            visible: wt.weather.ready
            text: wt.weather.area
            elide: Text.ElideRight
            font.pixelSize: 10
            font.capitalization: Theme.caps
            font.letterSpacing: Theme.tracking
            color: Theme.alpha(Theme.fg, 0.35)
        }
    }

    Item {
        id: graph
        anchors.left: now.right
        anchors.leftMargin: 14
        anchors.right: parent.right
        height: parent.height
        visible: wt.weather.ready

        readonly property var hours: wt.weather.hours
        readonly property real lo: Math.min(...hours.map(h => h.temp))
        readonly property real hi: Math.max(...hours.map(h => h.temp))
        readonly property real step: hours.length > 1 ? (width - 24) / (hours.length - 1) : 0
        function px(i) { return 12 + i * step }
        function py(t) { return 100 - (hi > lo ? (t - lo) / (hi - lo) : 0.5) * 50 }

        Canvas {
            anchors.fill: parent
            property var points: graph.hours.map((h, i) => [graph.px(i), graph.py(h.temp)])
            onPointsChanged: requestPaint()
            onWidthChanged: requestPaint()
            property color tint: Theme.caution
            onTintChanged: requestPaint()
            onPaint: {
                const c = getContext("2d")
                c.reset()
                const p = points
                if (p.length < 2) return
                const trace = () => {
                    c.beginPath()
                    c.moveTo(p[0][0], p[0][1])
                    for (let i = 1; i < p.length; i++) {
                        const mx = (p[i - 1][0] + p[i][0]) / 2
                        c.bezierCurveTo(mx, p[i - 1][1], mx, p[i][1], p[i][0], p[i][1])
                    }
                }
                trace()
                c.lineTo(p[p.length - 1][0], 118)
                c.lineTo(p[0][0], 118)
                c.closePath()
                const g = c.createLinearGradient(0, 40, 0, 118)
                g.addColorStop(0, Theme.alpha(Theme.caution, 0.28))
                g.addColorStop(1, Theme.alpha(Theme.info, 0))
                c.fillStyle = g
                c.fill()
                trace()
                c.lineWidth = 2
                c.strokeStyle = Theme.caution
                c.stroke()
            }
        }

        Repeater {
            model: graph.hours

            Item {
                required property var modelData
                required property int index
                x: graph.px(index) - 20
                width: 40
                height: graph.height

                LabelShared {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 2
                    text: wt.weather.glyph(modelData.code, modelData.night)
                    font.pixelSize: 14
                    color: Theme.fg
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: graph.py(modelData.temp) - 3
                    width: 6
                    height: 6
                    radius: Theme.round * 3
                    color: index === 0 ? Theme.bright : Theme.caution
                }
                LabelShared {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: graph.py(modelData.temp) - 20
                    text: modelData.temp + "°"
                    font.pixelSize: 10
                    font.capitalization: Theme.caps
                    font.letterSpacing: Theme.tracking
                    color: index === 0 ? Theme.bright : Theme.fg
                }
                LabelShared {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 128
                    text: index === 0 ? "Now" : modelData.label
                    font.pixelSize: 10
                    font.capitalization: Theme.caps
                    font.letterSpacing: Theme.tracking
                    color: Theme.dim
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: wt.weather.refresh(true)
    }
}
