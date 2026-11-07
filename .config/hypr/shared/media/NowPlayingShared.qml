import QtQuick

Item {
    id: np

    property var player: null
    property string title: ""
    property string artist: ""
    property string album: ""
    property string art: ""

    readonly property var raw: {
        const p = player
        if (!p) return { title: "", artist: "", album: "", art: "" }
        if (p.trackTitle || !MediaShared.isSpotify(p)) return { title: p.trackTitle || "", artist: p.trackArtist || "", album: p.trackAlbum || "", art: p.trackArtUrl || "" }
        const m = MediaShared.mirror
        if (!m) return null
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

    onRawChanged: {
        settle.interval = !title ? 0 : Date.now() - MediaShared.skipAt < 1500 ? 90 : 300
        settle.restart()
    }
    onPlayerChanged: { settle.stop(); if (raw) take(); else title = artist = album = art = "" }
    Component.onCompleted: take()
    Timer { id: settle; onTriggered: np.take() }
}
