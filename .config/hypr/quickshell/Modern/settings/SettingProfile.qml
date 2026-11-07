import QtQuick
import "../../shared"
import "../common"

Item {
    id: control

    property var def
    readonly property var styleNames: Object.keys(StoreShared.styles).sort()
    readonly property var variants: StoreShared.styles[StoreShared.active.style] || []

    function title(name) {
        return name.charAt(0).toUpperCase() + name.slice(1)
    }

    function options(list) {
        return list.map(n => ({ v: n, l: title(n) }))
    }

    implicitHeight: col.height

    Column {
        id: col
        width: parent.width

        Dropdown {
            width: parent.width
            label: "Style"
            options: control.options(control.styleNames)
            current: StoreShared.active.style
            onPicked: v => {
                if (v === StoreShared.active.style) return
                const list = StoreShared.styles[v] || []
                StoreShared.applyProfile(v, list.indexOf(StoreShared.active.variant) >= 0 ? StoreShared.active.variant : list[0])
            }
        }

        Rectangle { width: parent.width - Theme.pad * 2; x: Theme.pad; height: 1; color: Theme.alpha(Theme.fg, 0.07) }

        Dropdown {
            width: parent.width
            label: "Variant"
            options: control.options(control.variants)
            current: StoreShared.active.variant
            onPicked: v => { if (v !== StoreShared.active.variant) StoreShared.applyProfile(StoreShared.active.style, v) }
        }
    }
}
