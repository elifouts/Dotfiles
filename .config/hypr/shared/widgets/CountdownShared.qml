import QtQuick


Item {
    id: ft

    property int total: 25 * 60
    property int remaining: total
    property bool running: false
    property real endsAt: 0
    readonly property bool active: running || remaining < total
    readonly property real frac: total > 0 ? remaining / total : 0
    signal finished()

    function set(s) {
        running = false
        total = s
        remaining = s
    }

    function resume() {
        if (remaining <= 0) remaining = total
        endsAt = Date.now() + remaining * 1000
        running = true
    }

    function pause() {
        tick()
        running = false
    }

    function toggle() {
        running ? pause() : resume()
    }

    function reset() {
        running = false
        remaining = total
    }

    function tick() {
        remaining = Math.max(0, Math.ceil((endsAt - Date.now()) / 1000))
        if (remaining === 0 && running) {
            running = false
            remaining = total
            finished()
        }
    }

    function words(s) {
        const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60), r = s % 60
        return [h && h + " hour", m && m + " minute", r && r + " second"].filter(Boolean).join(" ")
    }

    function format(s) {
        const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60), r = s % 60
        const mm = (h > 0 && m < 10 ? "0" : "") + m
        return (h > 0 ? h + ":" : "") + mm + ":" + (r < 10 ? "0" : "") + r
    }

    Timer {
        interval: 250
        running: ft.running
        repeat: true
        onTriggered: ft.tick()
    }
}
