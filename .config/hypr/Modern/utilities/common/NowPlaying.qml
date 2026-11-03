import QtQuick

// what's playing. spotify blanks during music videos so this borrows from its chromium twin
Item {
    id: np

    property var player: null
    property string title: ""
    property string artist: ""
    property string album: ""
    property string art: ""

    // null = spotify went blank and the twin hasn't caught up, keep what's showing
    readonly property var raw: {
        const p = player
        if (!p) return { title: "", artist: "", album: "", art: "" }
        if (p.trackTitle || !Media.isSpotify(p)) return { title: p.trackTitle || "", artist: p.trackArtist || "", album: p.trackAlbum || "", art: p.trackArtUrl || "" }
        const m = Media.mirror
        if (!m) return null
        // twin says "title • artist" and has no cover, so keep ours if it's the same song
        const t = m.trackTitle, i = t.lastIndexOf(" • ")
        const title = t.slice(0, i), same = title === np.title
        return { title, artist: t.slice(i + 3), album: same ? np.album : "", art: same ? np.art : "" }
    }

    function take() {
        const r = raw
        if (!r) return
        title = r.title
        artist = r.artist
        album = r.album
        art = r.art
    }

    // waits out spotify's flashes, but barely when i just skipped
    onRawChanged: {
        settle.interval = !title ? 0 : Date.now() - Media.skipAt < 1500 ? 90 : 300
        settle.restart()
    }
    // new player shows right away, only track changes wait
    onPlayerChanged: { settle.stop(); if (raw) take(); else title = artist = album = art = "" }
    Component.onCompleted: take()
    Timer { id: settle; onTriggered: np.take() }
}
