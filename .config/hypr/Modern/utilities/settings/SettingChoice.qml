import QtQuick
import "../common"

Picker {

    property var def
    readonly property var raw: Store.values[def.key]

    label: def.label
    options: def.options.map(o => o.stops
        ? Object.assign({}, o, { swatch: o.stops.map(i => Theme.wal ? Theme.wal.colors["color" + i] : "#888888") })
        : o)
    ready: raw !== undefined && raw !== null
    current: {
        if (raw === "") {
            const d = def.options.find(o => o.dflt === true)
            return d ? d.v : raw
        }
        return raw
    }
    onPicked: v => Store.set(def.key, v)

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: Store.reset(def.key)
    }
}
