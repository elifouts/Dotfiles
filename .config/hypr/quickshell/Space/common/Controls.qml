import QtQuick
import "../../shared"

Item {
    component Title: Item {
        id: title
        property string glyph
        property string text
        default property alias extra: side.data
        width: parent?.width ?? 280
        height: 24
        Text { id: g; text: title.glyph; font.family: Theme.font; font.pixelSize: 14; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
        DecodeText { x: g.width + 8; text: title.text; color: Theme.fg; height: parent.height }
        Row { id: side; anchors.right: parent.right; height: parent.height; spacing: 10 }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.alpha(Theme.accent, 0.25) }
    }

    component Line: Item {
        id: line
        property string glyph
        property string text
        property string value
        property bool lit: false
        property bool hot: area.containsMouse
        signal clicked(var mouse)
        width: parent?.width ?? 280
        height: 24
        Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.accent, line.hot ? 0.1 : 0) }
        Rectangle { width: 2; height: parent.height; color: Theme.accent; visible: line.lit }
        Text { x: 8; text: line.glyph; font.family: Theme.font; font.pixelSize: 13; color: line.lit ? Theme.accent : Theme.dim; anchors.verticalCenter: parent.verticalCenter }
        DecodeText {
            caps: false
            x: line.glyph ? 28 : 8
            width: parent.width - x - val.width - 14
            text: line.text
            elide: Text.ElideRight
            font.pixelSize: 12
            color: line.lit || line.hot ? Theme.fg : Theme.dim
            anchors.verticalCenter: parent.verticalCenter
        }
        DecodeText { id: val; anchors.right: parent.right; anchors.rightMargin: 6; height: parent.height; text: line.value; color: line.lit ? Theme.accent : Theme.alpha(Theme.fg, 0.35) }
        MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.RightButton; onClicked: m => line.clicked(m) }
    }

    component Slide: Item {
        id: sl
        property real value: 0
        property string glyph
        property bool off: false
        property string readout
        property bool scrollable: true
        signal moved(real v)
        width: parent?.width ?? 280
        height: 22
        Text { id: sg; text: sl.glyph; width: sl.readout ? 0 : 20; font.family: Theme.font; font.pixelSize: 13; color: sl.off ? Theme.dim : Theme.accent; anchors.verticalCenter: parent.verticalCenter }
        Slider {
            x: sl.readout ? 0 : sg.width + 6
            width: parent.width - x - (sl.readout ? 58 : 40)
            height: parent.height
            value: sl.value
            dimmed: sl.off
            scrollable: sl.scrollable
            onMoved: v => sl.moved(v)
        }
        DecodeText { decode: false; anchors.right: parent.right; height: parent.height; text: sl.off ? "off" : sl.readout || Math.round(sl.value * 100); color: Theme.fg }
    }

    component Toggle: Item {
        id: tg
        property bool on
        property string text
        signal flip()
        implicitWidth: row.width
        width: row.width
        height: 24
        Row {
            id: row
            height: parent.height
            spacing: 8
            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                height: 16
                radius: 8
                color: Theme.alpha(Theme.accent, tg.on ? 0.35 : area.containsMouse ? 0.12 : 0.05)
                border.width: 1
                border.color: tg.on ? Theme.accent : Theme.alpha(Theme.fg, 0.3)
                Behavior on color { ColorAnimation { duration: Theme.fast } }
                Behavior on border.color { ColorAnimation { duration: Theme.fast } }
                Rectangle {
                    y: 3
                    x: tg.on ? parent.width - width - 3 : 3
                    width: 10
                    height: 10
                    radius: 5
                    color: tg.on ? Theme.accent : Theme.alpha(Theme.fg, 0.55)
                    scale: area.pressed ? 0.8 : 1
                    Behavior on x { NumberAnimation { duration: Theme.ms(180); easing.type: Easing.OutBack } }
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                    Behavior on scale { SettleShared { duration: Theme.ms(80) } }
                }
            }
            DecodeText { visible: tg.text !== ""; text: tg.text; height: parent.height; color: tg.on ? Theme.accent : Theme.dim }
        }
        MouseArea { id: area; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; onClicked: tg.flip() }
    }
}
