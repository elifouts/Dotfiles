import QtQuick
import "../../shared"
import "../common"

Item {
    id: control

    property var def
    readonly property var raw: StoreShared.values[def.key]
    readonly property bool ready: raw !== undefined && raw !== null
    readonly property bool on: ready && !!raw
    readonly property bool hot: area.containsMouse

    implicitHeight: 46
    opacity: ready ? 1 : 0.35

    LabelShared {
        anchors.left: parent.left
        anchors.leftMargin: Theme.pad
        anchors.right: knobTrack.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: control.def.label
        elide: Text.ElideRight
        font.pixelSize: 13
        color: control.hot ? Theme.bright : Theme.fg
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }

    Switch {
        id: knobTrack
        anchors.right: parent.right
        anchors.rightMargin: Theme.pad
        anchors.verticalCenter: parent.verticalCenter
        checked: control.on
        hot: control.hot
        enabled: false
    }

    HoverShared {
        id: area
        anchors.fill: parent
        enabled: control.ready
        onClicked: {
            const changes = {}
            changes[control.def.key] = !control.on
            const r = control.def.raises
            if (!control.on && r && StoreShared.values[r.key] < r.min) changes[r.key] = r.min
            StoreShared.setMany(changes)
        }
    }

    ResetArea { key: control.def.key }
}
