import QtQuick
import "../../shared"
import "../common"

Picker {

    component Picker: Item {
        id: pick

        property string label
        property var options: []
        property var current
        property bool ready: true
        signal picked(var value)

        readonly property bool many: options.length >= 5
        readonly property bool inline: options.length <= 2

        implicitHeight: many ? dd.implicitHeight : (inline ? 48 : 76)
        opacity: ready ? 1 : 0.35
        enabled: ready

        Dropdown {
            id: dd
            visible: pick.many
            width: parent.width
            label: pick.label
            options: pick.options
            current: pick.current
            onPicked: v => pick.picked(v)
        }

        LabelShared {
            visible: !pick.many
            x: Theme.pad
            y: pick.inline ? (pick.height - height) / 2 : 12
            text: pick.label
            font.pixelSize: 13
            color: Theme.fg
        }

        Segmented {
            visible: !pick.many
            x: pick.inline ? pick.width - width - Theme.pad : Theme.pad
            y: pick.inline ? (pick.height - height) / 2 : 36
            width: pick.inline ? Math.min(pick.options.length * 84, pick.width * 0.6) : pick.width - Theme.pad * 2
            options: pick.options
            current: pick.current
            onPicked: v => pick.picked(v)
        }
    }

    property var def
    readonly property var raw: StoreShared.values[def.key]

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
    onPicked: v => StoreShared.set(def.key, v)

    ResetArea { key: def.key }
}
