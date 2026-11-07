import QtQuick
import Quickshell.Io


Item {
    id: fc

    property bool ready: false
    property bool failed: false
    property int temp: 0
    property int feels: 0
    property int high: 0
    property int low: 0
    property int humidity: 0
    property int wind: 0
    property int code: 113
    property bool night: false
    property string desc: ""
    property string area: ""
    property var hours: []
    property real fetchedAt: 0

    function refresh(force) {
        if (!force && Date.now() - fetchedAt < 10 * 60 * 1000) return
        if (!proc.running) proc.running = true
    }

    function glyph(c, dark) {
        if (c === 113) return dark ? "󰖔" : "󰖙"
        if (c === 116) return "󰖕"
        if ([119, 122].includes(c)) return "󰖐"
        if ([143, 248, 260].includes(c)) return "󰖑"
        if ([200, 386, 389, 392, 395].includes(c)) return "󰖓"
        if ([299, 302, 305, 308, 356, 359].includes(c)) return "󰖖"
        if ([179, 182, 185, 227, 230, 311, 314, 317, 320, 323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377].includes(c)) return "󰖘"
        return "󰖗"
    }

    Timer { interval: 30 * 60 * 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: fc.refresh(true) }

    Process {
        id: proc
        command: ["curl", "-sf", "--max-time", "10", "https://wttr.in/?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text)
                    const c = d.current_condition[0], a = d.nearest_area[0], today = d.weather[0]
                    const hour = new Date().getHours()
                    fc.temp = +c.temp_F
                    fc.feels = +c.FeelsLikeF
                    fc.humidity = +c.humidity
                    fc.wind = +c.windspeedMiles
                    fc.code = +c.weatherCode
                    fc.desc = (c.weatherDesc[0].value || "").trim()
                    fc.area = [a.areaName[0].value, a.region[0].value].filter(s => !!s).join(", ")
                    fc.high = +today.maxtempF
                    fc.low = +today.mintempF
                    fc.night = hour < 6 || hour >= 20
                    const now = Date.now(), list = []
                    for (let day = 0; day < 2; day++) {
                        const date = d.weather[day].date
                        for (const h of d.weather[day].hourly) {
                            const hh = Math.floor(+h.time / 100)
                            const at = new Date(date + "T" + String(hh).padStart(2, "0") + ":00:00").getTime()
                            if (at < now - 90 * 60 * 1000) continue
                            list.push({ temp: +h.tempF, code: +h.weatherCode, night: hh < 6 || hh >= 20,
                                        label: (hh % 12 || 12) + (hh < 12 ? "a" : "p") })
                        }
                    }
                    fc.hours = list.slice(0, 7)
                    fc.ready = true
                    fc.failed = false
                    fc.fetchedAt = Date.now()
                } catch (e) {
                    fc.failed = true
                }
            }
        }
        onExited: code => { if (code !== 0) fc.failed = true }
    }
}
