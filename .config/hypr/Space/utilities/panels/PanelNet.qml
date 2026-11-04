import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import "../common"
import "../ui"

Column {
    id: net
    spacing: 6

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var networks: wifi ? wifi.networks.values.filter(n => n.name).sort((a, b) =>
        (b.connected - a.connected) || (b.known - a.known) || ((b.signalStrength ?? 0) - (a.signalStrength ?? 0))).slice(0, 7) : []
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: adapter ? adapter.devices.values.filter(d => d.paired || d.connected || d.name)
        .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired)).slice(0, 6) : []
    property string asking: ""

    Binding { target: net.wifi; property: "scannerEnabled"; value: true; when: !!net.wifi && Networking.wifiEnabled }

    function secured(n) { return n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe }
    function pick(n) {
        if (n.connected) return n.disconnect()
        if (n.known || !secured(n)) return n.connect()
        asking = n.name
    }
    Process { id: join }

    Kit.Title { glyph: "󰤨"; text: "wifi"; Kit.Toggle { on: Networking.wifiEnabled; onFlip: Networking.wifiEnabled = !Networking.wifiEnabled } }
    Repeater {
        model: net.networks
        Kit.Line {
            required property var modelData
            readonly property real sig: (modelData.signalStrength ?? 0) > 1 ? modelData.signalStrength / 100 : (modelData.signalStrength ?? 0)
            glyph: sig > 0.66 ? "󰤨" : sig > 0.33 ? "󰤥" : "󰤟"
            text: modelData.name
            value: modelData.connected ? "linked" : net.secured(modelData) && !modelData.known ? "󰌾" : ""
            lit: modelData.connected
            onClicked: net.pick(modelData)
        }
    }
    Field {
        visible: net.asking !== ""
        placeholder: "password for " + net.asking
        secret: true
        onAccepted: {
            join.command = ["nmcli", "--wait", "30", "device", "wifi", "connect", net.asking, "password", text]
            join.running = true
            net.asking = ""
            text = ""
        }
    }

    Item { width: 1; height: 6 }
    Kit.Title {
        glyph: "󰂯"
        text: "bluetooth"
        Kit.Toggle { visible: !!net.adapter; on: !!net.adapter && net.adapter.enabled; onFlip: net.adapter.enabled = !net.adapter.enabled }
    }
    Repeater {
        model: net.adapter?.enabled ? net.devices : []
        Kit.Line {
            required property var modelData
            glyph: "󰂱"
            text: modelData.name || modelData.address
            value: modelData.connected ? "linked" : modelData.paired ? "paired" : "pair"
            lit: modelData.connected
            onClicked: modelData.connected ? modelData.disconnect() : modelData.paired ? modelData.connect() : modelData.pair()
        }
    }
}
