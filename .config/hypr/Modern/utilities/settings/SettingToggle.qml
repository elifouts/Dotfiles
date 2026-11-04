import QtQuick
import "../common"

Item {
    id: control

    property var def
    readonly property var raw: Store.values[def.key]
    readonly property bool ready: raw !== undefined && raw !== null
    readonly property bool on: ready && !!raw
    readonly property bool hot: area.containsMouse

    implicitHeight: 46
    opacity: ready ? 1 : 0.35

    Label {
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

    Hover {
        id: area
        anchors.fill: parent
        enabled: control.ready
        onClicked: {
            const changes = {}
            changes[control.def.key] = !control.on
            const r = control.def.raises
            if (!control.on && r && Store.values[r.key] < r.min) changes[r.key] = r.min
            Store.setMany(changes)
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: Store.reset(control.def.key)
    }
}
