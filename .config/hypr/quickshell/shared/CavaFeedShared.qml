import QtQuick
import Quickshell
import Quickshell.Io

Process {
    id: feed

    property int bars: 36
    property int framerate: 30
    property var levels: []

    command: ["sh", "-c", 'c="${XDG_RUNTIME_DIR:-/tmp}/cava-$1-$2.conf"; sed "s/^bars = .*/bars = $1/; s/^framerate = .*/framerate = $2/" "$0" > "$c" && exec cava -p "$c"',
              Quickshell.shellPath("shared/cava.conf"), String(bars), String(framerate)]
    stdout: SplitParser {
        onRead: line => {
            const parts = line.trim().split(";")
            if (parts.length < feed.bars) return
            const out = new Array(feed.bars)
            for (let i = 0; i < feed.bars; i++) out[i] = Math.max(0, Math.min(1, (parseInt(parts[i]) || 0) / 1000))
            feed.levels = out
        }
    }
    onRunningChanged: if (!running) levels = []
}
