pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var players: Mpris.players.values.filter(p => !(p.dbusName || "").includes("playerctld") && (p.trackTitle || isSpotify(p)) && p !== mirror)
    readonly property var mirror: Mpris.players.values.some(isSpotify)
        ? Mpris.players.values.find(p => (p.dbusName || "").includes("chromium") && (p.trackTitle || "").includes(" • ")) ?? null
        : null

    function pickPlayer(pinned) {
        const ps = players
        return ps.find(p => pinned && p.dbusName === pinned) ?? ps.find(isSpotify) ?? ps.find(p => p.isPlaying) ?? ps[0] ?? null
    }
    property int skipWay: 1
    property real skipAt: 0
    signal skipped(var player, int dir)
    function skip(p, d) {
        if (!p || !(d > 0 ? p.canGoNext : p.canGoPrevious)) return
        skipWay = d
        skipAt = Date.now()
        if (d > 0) p.next()
        else p.previous()
        skipped(p, d)
    }
    function skipDir() { return Date.now() - skipAt < 2500 ? skipWay : 1 }
    property var guessFor: null
    property bool guess: false
    function playing(p) { return !!p && (p === guessFor ? guess : p.isPlaying) }
    function toggle(p) {
        if (!p || !p.canTogglePlaying) return
        guess = !playing(p)
        guessFor = p
        guessEnd.restart()
        p.togglePlaying()
    }
    Timer { id: guessEnd; interval: 1500; onTriggered: root.guessFor = null }

    property int views: 0
    property bool card: false
    signal dropCard()
    property string side: "center"

    function isSpotify(x) {
        return !!x && [x.identity, x.dbusName, x.id, x.title, x.tooltipTitle].some(s => (s || "").toLowerCase().includes("spotify"))
    }

    function openSpotify() {
        Quickshell.execDetached([Quickshell.shellDir + "/shared/spotify.sh"])
    }
}
