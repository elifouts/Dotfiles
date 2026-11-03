pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// what the osd does, each style draws it its own way
Singleton {
    id: root

    property bool caps: false
    signal shown(string kind)
    // play / next / prev, each style shows media its own way
    signal media(string action)

    function value(kind) { return kind === "volume" ? Audio.volume : kind === "brightness" ? Brightness.value : 0 }
    function flag(kind) {
        return kind === "volume" ? Audio.muted : kind === "mic" ? !!Audio.source?.audio?.muted : kind === "caps" ? caps : false
    }

    function act(a) {
        const out = Audio.sink?.audio, mic = Audio.source?.audio
        switch (a) {
        case "vol-up": case "vol-down":
            if (out) {
                out.muted = false
                out.volume = Math.max(0, Math.min(1, Math.round((out.volume + (a === "vol-up" ? 0.05 : -0.05)) * 20) / 20))
            }
            return shown("volume")
        case "vol-mute": if (out) out.muted = !out.muted; return shown("volume")
        case "mic-mute": if (mic) mic.muted = !mic.muted; return shown("mic")
        // no caps event, so flip ours and check the led once the spam stops
        case "caps": caps = !caps; capsGen++; capsCheck.restart(); return shown("caps")
        case "play": case "next": case "prev": return media(a)
        }
    }
    function brightness(v) { Brightness.value = v; shown("brightness") }

    property int capsGen: 0
    Timer { id: capsCheck; interval: 150; onTriggered: capsLed.check() }
    Process {
        id: capsLed
        property int gen
        function check() { gen = root.capsGen; running = true }
        command: ["sh", "-c", "cat /sys/class/leds/*capslock/brightness"]
        // a press that lands mid-read makes the answer useless, the timer reruns it anyway
        stdout: StdioCollector { onStreamFinished: if (capsLed.gen === root.capsGen) root.caps = text.split("\n").some(l => l.trim() !== "" && l.trim() !== "0") }
    }
    Component.onCompleted: capsLed.check()
}
