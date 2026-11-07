import QtQuick
import Quickshell.Services.Pipewire
import "../style/common"
import "../style/bar/menus"

Grid {
    id: menu

    component Level: Column {
        id: lv
        property var node
        property string title
        property string glyph
        property string mutedGlyph
        property string device
        readonly property bool ok: !!node && !!node.audio
        readonly property real vol: ok ? node.audio.volume : 0
        readonly property bool muted: ok && node.audio.muted
        width: parent.width
        spacing: 6

        Item {
            width: parent.width
            height: 16
            Say {
                x: 4
                anchors.verticalCenter: parent.verticalCenter
                text: lv.title.toUpperCase()
                font.pixelSize: 10
                font.letterSpacing: 1.6
                color: Theme.dim
            }
            Say {
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.left: parent.horizontalCenter
                horizontalAlignment: Text.AlignRight
                anchors.verticalCenter: parent.verticalCenter
                text: lv.ok ? lv.device : "None"
                elide: Text.ElideRight
                font.pixelSize: 10
                color: Theme.dim
            }
        }

        Tile {
            width: parent.width
            height: 44
            opacity: lv.ok ? 1 : 0.45

            LabelShared {
                id: muteBtn
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                text: lv.muted ? lv.mutedGlyph : lv.glyph
                font.pixelSize: 16
                color: lv.muted ? Theme.dim : muteArea.containsMouse ? Theme.accent : Theme.bright
                HoverShared {
                    id: muteArea
                    anchors.fill: parent
                    anchors.margins: -6
                    onClicked: if (lv.ok) lv.node.audio.muted = !lv.node.audio.muted
                }
            }

            Slider {
                anchors.left: muteBtn.right
                anchors.leftMargin: 12
                anchors.right: pct.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                value: lv.vol
                dimmed: lv.muted
                step: 0.02
                onMoved: v => { if (lv.ok) { lv.node.audio.volume = v; if (v > 0) lv.node.audio.muted = false } }
            }

            LabelShared {
                id: pct
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                horizontalAlignment: Text.AlignRight
                text: Math.round(lv.vol * 100) + "%"
                font.pixelSize: 12
                color: Theme.fg
            }
        }
    }

    property bool open: false
    signal run(string cmd)
    signal done()

    readonly property real colW: columns === 2 ? (width - columnSpacing) / 2 : width
    columns: width >= 600 ? 2 : 1
    columnSpacing: 22
    rowSpacing: 12

    readonly property var sink: AudioShared.sink
    readonly property var source: AudioShared.source
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
            glyph: menu.volGlyph(AudioShared.volume)
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
