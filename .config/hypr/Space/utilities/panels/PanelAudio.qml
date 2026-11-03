import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../common"
import "../ui"

// volume, mic and which device, same Audio singleton as modern
Column {
    id: au
    spacing: 6

    readonly property var devices: Pipewire.nodes.values.filter(n => n.audio && !n.isStream)
    PwObjectTracker { objects: au.devices }

    Kit.Title { glyph: "󰕾"; text: "sound" }
    Kit.Slide {
        glyph: Audio.muted ? "󰝟" : "󰕾"
        value: Audio.volume
        off: Audio.muted
        onMoved: v => Audio.setVolume(v)
        MouseArea { width: 20; height: parent.height; onClicked: Audio.toggleMute() }
    }
    Kit.Slide {
        readonly property var mic: Audio.source?.audio
        glyph: mic?.muted ? "󰍭" : "󰍬"
        value: mic?.volume ?? 0
        off: !!mic?.muted
        onMoved: v => { if (mic) { mic.volume = v; mic.muted = false } }
        MouseArea { width: 20; height: parent.height; onClicked: if (parent.mic) parent.mic.muted = !parent.mic.muted }
    }

    Item { width: 1; height: 4 }
    Kit.Title { glyph: "󰓃"; text: "output" }
    Repeater {
        model: au.devices.filter(n => n.isSink)
        Kit.Line {
            required property var modelData
            text: modelData.description || modelData.nickname || modelData.name
            lit: modelData === Audio.sink
            onClicked: Pipewire.preferredDefaultAudioSink = modelData
        }
    }
    Kit.Title { glyph: "󰍬"; text: "input" }
    Repeater {
        model: au.devices.filter(n => !n.isSink && !(n.name || "").endsWith(".monitor"))
        Kit.Line {
            required property var modelData
            text: modelData.description || modelData.nickname || modelData.name
            lit: modelData === Audio.source
            onClicked: Pipewire.preferredDefaultAudioSource = modelData
        }
    }
}
