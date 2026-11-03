import QtQuick
import Quickshell.Bluetooth
import "../../common"

Column {
    id: menu

    property bool open: false

    spacing: 12

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: !!adapter && adapter.enabled
    readonly property var all: adapter ? adapter.devices.values : []
    readonly property var paired: all.filter(d => d.paired || d.connected)
        .sort((a, b) => (b.connected - a.connected) || label(a).localeCompare(label(b)))
    readonly property var nearby: all.filter(d => !d.paired && !d.connected && d.name && d.name !== d.address.replace(/:/g, "-"))
        .sort((a, b) => label(a).localeCompare(label(b)))
    property var pending: ({})
    // rows get rebuilt when a device moves lists, this lets the new one still do the spin
    property var trying: ({})
    function mark(d) { trying[d.address] = Date.now() }
    function fresh(d) {
        const t = trying[d.address] ?? 0
        delete trying[d.address]
        return Date.now() - t < 4000
    }

    Binding {
        target: menu.adapter
        property: "discovering"
        value: true
        when: menu.open && menu.on
        restoreMode: Binding.RestoreBindingOrValue
    }

    function label(d) {
        return d.name || d.deviceName || d.address
    }

    function glyph(d) {
        const i = (d.icon || "").toLowerCase()
        if (i.includes("headset") || i.includes("headphone")) return "󰋋"
        if (i.includes("audio") || i.includes("speaker")) return "󰓃"
        if (i.includes("keyboard")) return "󰌌"
        if (i.includes("mouse")) return "󰍽"
        if (i.includes("phone")) return "󰄜"
        if (i.includes("gaming") || i.includes("joystick")) return "󰊴"
        if (i.includes("computer")) return "󰌢"
        return "󰂯"
    }

    function status(d) {
        if (d.pairing) return "Pairing"
        if (d.state === BluetoothDeviceState.Connecting) return "Connecting"
        if (d.state === BluetoothDeviceState.Disconnecting) return "Disconnecting"
        return ""
    }

    function pick(d) {
        if (d.connected) d.disconnect()
        else if (d.paired) d.connect()
        else {
            pending = Object.assign({}, pending, { [d.address]: true })
            d.trusted = true
            d.pair()
        }
    }

    Header {
        title: "Bluetooth"
        Switch {
            checked: menu.on
            onToggled: if (menu.adapter) menu.adapter.enabled = !menu.adapter.enabled
        }
    }

    Group {
        maxHeight: 166
        empty: !menu.adapter ? "No adapter" : !menu.on ? "Off" : "No devices"

        Repeater {
            model: menu.on ? menu.paired : []
            DeviceRow { owner: menu }
        }
    }

    Group {
        maxHeight: 130
        visible: menu.on
        empty: "Searching…"

        Repeater {
            model: menu.on ? menu.nearby : []
            DeviceRow { owner: menu }
        }
    }
}
