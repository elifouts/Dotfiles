import QtQuick
import "../../shared"

Item {
    component Title: Item {
        id: title
        property string glyph
        property string text
        default property alias extra: side.data
        width: parent?.width ?? 280
        height: 22
        Rectangle { anchors.verticalCenter: parent.verticalCenter; x: chip.width; width: parent.width - x; height: 1; color: Theme.low }
        Item {
            id: chip
            width: label.implicitWidth + (title.glyph ? 26 : 10)
            height: parent.height
            Text { visible: !!title.glyph; text: title.glyph; font.family: Theme.font; font.pixelSize: Theme.size; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
            Type { id: label; x: title.glyph ? 20 : 0; height: parent.height; text: title.text; color: Theme.accent }
        }
        Row { id: side; anchors.right: parent.right; height: parent.height; spacing: 10 }
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
        height: Theme.menuRow
        readonly property color ink: line.hot ? Theme.bg : line.lit ? Theme.accent : Theme.fg
        Rectangle { anchors.fill: parent; color: line.hot ? Theme.accent : "transparent" }
        Text { x: 4; text: line.lit && !line.glyph ? "▶" : line.glyph; font.family: Theme.font; font.pixelSize: Theme.size; color: line.ink; anchors.verticalCenter: parent.verticalCenter }
        Type {
            caps: false
            x: 24
            width: parent.width - x - val.width - 10
            height: parent.height
            text: line.text
            elide: Text.ElideRight
            color: line.ink
        }
        Type { id: val; anchors.right: parent.right; anchors.rightMargin: 4; height: parent.height; text: line.value; color: line.hot ? Theme.bg : Theme.dim }
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
        Text { id: sg; text: sl.glyph; width: sl.glyph ? 22 : 0; font.family: Theme.font; font.pixelSize: Theme.size; color: sl.off ? Theme.dim : Theme.accent; anchors.verticalCenter: parent.verticalCenter }
        Slider {
            x: sg.width
            width: parent.width - x - readout.width - 8
            height: parent.height
            value: sl.value
            dimmed: sl.off
            scrollable: sl.scrollable
            onMoved: v => sl.moved(v)
        }
        Type { id: readout; type: false; width: Math.max(36, implicitWidth); horizontalAlignment: Text.AlignRight; anchors.right: parent.right; height: parent.height; text: sl.off ? "off" : sl.readout || Math.round(sl.value * 100); color: Theme.fg }
    }

    component Toggle: Item {
        id: tg
        property bool on
        property string text
        signal flip()
        implicitWidth: row.implicitWidth
        width: implicitWidth
        height: 22
        Row {
            id: row
            height: parent.height
            spacing: 6
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: box.implicitWidth + 4
                height: parent.height - 4
                color: area.containsMouse ? Theme.low : "transparent"
                Text { id: box; anchors.centerIn: parent; text: tg.on ? "[■]" : "[ ]"; font.family: Theme.font; font.pixelSize: Theme.size; color: tg.on ? Theme.accent : Theme.dim }
            }
            Type { visible: tg.text !== ""; text: tg.text; height: parent.height; color: tg.on ? Theme.accent : Theme.dim }
        }
        MouseArea { id: area; anchors.fill: parent; anchors.margins: -3; hoverEnabled: true; onClicked: tg.flip() }
    }
}
