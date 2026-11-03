import QtQuick
import Quickshell.Services.Pipewire
import "../../common"

Grid {
    id: menu

    property bool open: false
    signal run(string cmd)
    signal done()

    readonly property real colW: columns === 2 ? (width - columnSpacing) / 2 : width
    columns: width >= 600 ? 2 : 1
    columnSpacing: 22
    rowSpacing: 12

    readonly property var sink: Audio.sink
    readonly property var source: Audio.source
    readonly property var devices: Pipewire.nodes.values.filter(n => n.audio && !n.isStream)
    readonly property var outputs: devices.filter(n => n.isSink)
    readonly property var inputs: devices.filter(n => !n.isSink && !(n.name || "").endsWith(".monitor"))

    PwObjectTracker { objects: menu.open ? menu.devices : [] }

    function name(n) {
        return n.nickname || n.description || n.name
    }

    function volGlyph(v) {
        return v > 0.66 ? "󰕾" : v > 0.33 ? "󰖀" : "󰕿"
    }

    Column {
        width: menu.colW
        spacing: 12

        Header { title: "Sound" }

        Level {
            node: menu.sink
            device: menu.sink ? menu.name(menu.sink) : ""
            title: "Output"
            glyph: menu.volGlyph(Audio.volume)
            mutedGlyph: "󰝟"
        }

        Level {
            node: menu.source
            device: menu.source ? menu.name(menu.source) : ""
            title: "Microphone"
            glyph: "󰍬"
            mutedGlyph: "󰍭"
        }
    }

    Column {
        width: menu.colW
        spacing: 12

        Group {
            title: "Output device"
            maxHeight: 170
            empty: "No outputs"
            Repeater {
                model: menu.outputs
                Entry {
                    required property var modelData
                    glyph: "󰓃"
                    label: menu.name(modelData)
                    active: menu.sink === modelData
                    trailing: active ? "" : ""
                    onClicked: Pipewire.preferredDefaultAudioSink = modelData
                }
            }
        }

        Group {
            title: "Input device"
            maxHeight: 130
            visible: menu.inputs.length > 0
            Repeater {
                model: menu.inputs
                Entry {
                    required property var modelData
                    glyph: "󰍬"
                    label: menu.name(modelData)
                    active: menu.source === modelData
                    trailing: active ? "" : ""
                    onClicked: Pipewire.preferredDefaultAudioSource = modelData
                }
            }
        }

        Group {
            Entry {
                glyph: "󰕾"
                label: "Mixer"
                sub: "Per-app volume"
                onClicked: { menu.run("pypr toggle music 2>/dev/null || pavucontrol"); menu.done() }
            }
        }
    }
}
