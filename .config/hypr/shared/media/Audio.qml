pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: !!sink?.audio?.muted
    PwObjectTracker { objects: [root.sink, root.source] }

    function setVolume(v) {
        if (!sink?.audio) return
        sink.audio.volume = Math.max(0, Math.min(1, v))
        if (v > 0) sink.audio.muted = false
    }
    function nudge(dir) { setVolume(Math.round((volume + dir * 0.02) * 50) / 50) }
    function toggleMute() { if (sink?.audio) sink.audio.muted = !sink.audio.muted }
}
