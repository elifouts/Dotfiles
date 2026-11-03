pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    // skip playerctld, it keeps the last track after players stop
    // and anything with no track, plus spotify's chromium twin (NowPlaying borrows its title)
    readonly property var players: Mpris.players.values.filter(p => !(p.dbusName || "").includes("playerctld") && (p.trackTitle || isSpotify(p)) && p !== mirror)
    // spotify plays music videos through its own chromium, that one says "title • artist"
    readonly property var mirror: Mpris.players.values.some(isSpotify)
        ? Mpris.players.values.find(p => (p.dbusName || "").includes("chromium") && (p.trackTitle || "").includes(" • ")) ?? null
        : null

    // pinned one, then spotify cause that's what i use, then whatever's playing, then whatever
    function pickPlayer(pinned) {
        const ps = players
        return ps.find(p => pinned && p.dbusName === pinned) ?? ps.find(isSpotify) ?? ps.find(p => p.isPlaying) ?? ps[0] ?? null
    }

    // every skip goes through here so all the cards slide the same way
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

    // flips on the press, mpris answering late felt awful
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

    // open media screens, the osd card stays out of their way
    property int views: 0
    // osd's music card is up, the bar tucks its media chip away for it
    property bool card: false
    // bar asks it to leave before opening the media page over it
    signal dropCard()
    // which pill the bar's media lives in, the card drops out of the bar there
    property string side: "center"

    function isSpotify(x) {
        return !!x && [x.identity, x.dbusName, x.id, x.title, x.tooltipTitle].some(s => (s || "").toLowerCase().includes("spotify"))
    }

    function openSpotify() {
        Quickshell.execDetached([Quickshell.shellDir + "/common/spotify.sh"])
    }
}
