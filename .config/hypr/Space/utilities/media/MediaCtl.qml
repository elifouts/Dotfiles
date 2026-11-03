import QtQuick
import Quickshell
import "../common"
import "../ui"

// now playing, the bar panel and the desk widget both use this
Column {
    id: mc
    spacing: 10 * s
    width: parent?.width ?? 300
    property real s: 1
    property color ink: Theme.fg

    readonly property var player: Media.pickPlayer("")
    readonly property bool playing: Media.playing(player)
    readonly property real len: Math.max(1, player?.length ?? 1)
    NowPlaying { id: now; player: mc.player }

    // local clock: position = base + elapsed, advanced every frame
    property real base: 0
    property real baseT: Date.now()
    property real pos: 0
    property bool dragging: false
    property real settleUntil: 0
    // set from handlers not a binding, reading the mpris length mid-binding looped and spammed the log
    property real frac: 0
    function refrac() { frac = Math.max(0, Math.min(1, pos / len)) }
    onPosChanged: refrac()
    onLenChanged: refrac()

    function sync() {
        player?.positionChanged()
        base = player?.position ?? 0
        baseT = Date.now()
        pos = base
    }
    function fmt(t) {
        t = Math.max(0, Math.floor(t))
        const m = Math.floor(t / 60), r = t % 60
        return String(m).padStart(2, "0") + ":" + String(r).padStart(2, "0")
    }
    onPlayingChanged: sync()
    onPlayerChanged: sync()
    Connections { target: now; function onTitleChanged() { mc.sync() } }

    // 4 times a second is plenty for a seek bar, this was a FrameAnimation and kept the wallpaper redrawing at full refresh
    Timer {
        running: mc.visible && mc.playing && !mc.dragging
        interval: 250
        repeat: true
        onTriggered: mc.pos = Math.min(mc.len, mc.base + (Date.now() - mc.baseT) / 1000)
    }
    // drift check only, small jitter is ignored so the bar never steps
    Timer {
        running: mc.visible && mc.playing && !mc.dragging
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (Date.now() < mc.settleUntil) return
            mc.player?.positionChanged()
            const p = mc.player?.position ?? 0
            if (Math.abs(p - mc.pos) > 0.5) { mc.base = p; mc.baseT = Date.now(); mc.pos = p }
        }
    }

    // transport button: hover grow, press squash, springy release
    component Btn: Item {
        id: b
        property string glyph
        property bool primary: false
        property real s: 1
        property color ink
        signal clicked()

        width: (primary ? 40 : 32) * s
        height: width
        opacity: enabled ? 1 : 0.35

        Item {
            anchors.fill: parent
            scale: ma.pressed ? 0.84 : (ma.containsMouse ? 1.08 : 1)
            Behavior on scale {
                NumberAnimation {
                    duration: ma.pressed ? 70 : 240
                    easing.type: ma.pressed ? Easing.OutQuad : Easing.OutBack
                }
            }
            Rectangle {
                anchors.fill: parent
                visible: b.primary
                color: Theme.alpha(Theme.accent, ma.pressed ? 0.28 : (ma.containsMouse ? 0.16 : 0.08))
                border.width: 1
                border.color: Theme.alpha(Theme.accent, ma.containsMouse ? 0.9 : 0.4)
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }
            }
            Text {
                anchors.centerIn: parent
                text: b.glyph
                font.family: Theme.font
                font.pixelSize: (b.primary ? 20 : 15) * b.s
                color: ma.containsMouse ? Theme.accent : b.ink
                Behavior on color { ColorAnimation { duration: 120 } }
            }
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: b.clicked()
        }
    }

    // art + track info, centred like the transport under it
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 12 * mc.s
        Rectangle {
            width: 52 * mc.s
            height: width
            color: Theme.alpha(Theme.accent, 0.12)
            border.width: 1
            border.color: Theme.alpha(Theme.accent, 0.4)
            Image { anchors.fill: parent; anchors.margins: 1; source: now.art; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(width, height); asynchronous: true }
            // fill + align, centerIn left nerd glyphs sitting off to one side
            Text { anchors.fill: parent; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; visible: !now.art; text: "󰎈"; font.family: Theme.font; font.pixelSize: 20 * mc.s; color: Theme.accent }
        }
        Column {
            // as wide as the longest line, so short titles stay centred instead of hugging the art
            width: Math.min(mc.width - 64 * mc.s, Math.max(who.implicitWidth, title.implicitWidth, artist.implicitWidth))
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Hud { id: who; text: mc.player ? mc.player.identity : "nothing playing"; font.pixelSize: 9 * mc.s; color: Theme.dim }
            Hud {
                id: title
                caps: false
                width: parent.width
                text: now.title || "—"
                elide: Text.ElideRight
                font.family: Theme.font
                font.pixelSize: 14 * mc.s
                color: mc.ink
            }
            Hud {
                id: artist
                caps: false
                width: parent.width
                visible: text !== ""
                text: [now.artist, now.album].filter(Boolean).join("  ·  ")
                elide: Text.ElideRight
                font.family: Theme.font
                font.pixelSize: 11 * mc.s
                color: Theme.alpha(mc.ink, 0.65)
            }
        }
    }

    // transport
    Row {
        spacing: 6 * mc.s
        anchors.horizontalCenter: parent.horizontalCenter
        Btn {
            glyph: "󰒮"; s: mc.s; ink: mc.ink
            anchors.verticalCenter: parent.verticalCenter
            enabled: !!mc.player
            onClicked: Media.skip(mc.player, -1)
        }
        Btn {
            glyph: mc.playing ? "󰏤" : "󰐊"; primary: true; s: mc.s; ink: mc.ink
            anchors.verticalCenter: parent.verticalCenter
            enabled: !!mc.player
            onClicked: Media.toggle(mc.player)
        }
        Btn {
            glyph: "󰒭"; s: mc.s; ink: mc.ink
            anchors.verticalCenter: parent.verticalCenter
            enabled: !!mc.player
            onClicked: Media.skip(mc.player, 1)
        }
    }

    // HUD seek: readouts, tick scale, glowing progress line, blade playhead
    Item {
        id: seekBar
        width: parent.width
        height: 34 * mc.s
        visible: (mc.player?.length ?? 0) > 0
        readonly property bool active: sma.containsMouse || mc.dragging
        readonly property int ticks: Math.max(16, Math.round(width / (6 * mc.s)))
        readonly property real barY: 24 * mc.s

        // readouts
        Hud {
            caps: false
            anchors.left: parent.left
            anchors.top: parent.top
            text: mc.fmt(mc.pos)
            font.family: Theme.font
            font.pixelSize: 9 * mc.s
            font.letterSpacing: 1.5
            color: Theme.accent
        }
        Hud {
            caps: false
            anchors.right: parent.right
            anchors.top: parent.top
            text: "-" + mc.fmt(mc.len - mc.pos)
            font.family: Theme.font
            font.pixelSize: 9 * mc.s
            font.letterSpacing: 1.5
            color: Theme.dim
        }
        Hud {
            caps: false
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            text: Math.round(mc.frac * 100) + "%"
            font.family: Theme.font
            font.pixelSize: 9 * mc.s
            font.letterSpacing: 1.5
            color: Theme.alpha(mc.ink, seekBar.active ? 0.7 : 0.3)
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // tick scale; each tick brightens continuously as the playhead passes
        Repeater {
            model: seekBar.ticks
            Rectangle {
                required property int index
                readonly property real a: Math.max(0, Math.min(1, mc.frac * seekBar.ticks - index))
                x: index / (seekBar.ticks - 1) * (seekBar.width - width)
                width: 1
                height: (index % 4 === 0 ? 7 : 4) * mc.s
                y: seekBar.barY - height - 2 * mc.s
                color: Theme.alpha(Theme.accent, 0.12 + 0.55 * a)
            }
        }

        // baseline + end brackets
        Rectangle { x: 0; y: seekBar.barY; width: parent.width; height: 1; color: Theme.faint }
        Rectangle { x: 0; y: seekBar.barY - 4 * mc.s; width: 1; height: 9 * mc.s; color: Theme.alpha(Theme.accent, 0.6) }
        Rectangle { x: parent.width - 1; y: seekBar.barY - 4 * mc.s; width: 1; height: 9 * mc.s; color: Theme.alpha(Theme.accent, 0.6) }

        // progress: glow + core line
        Rectangle {
            x: 0
            y: seekBar.barY - 2 * mc.s
            width: parent.width * mc.frac
            height: 5 * mc.s
            color: Theme.alpha(Theme.accent, seekBar.active ? 0.28 : 0.16)
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        Rectangle {
            x: 0
            y: seekBar.barY
            width: parent.width * mc.frac
            height: 1
            color: Theme.accent
        }

        // playhead: blade
        Item {
            x: parent.width * mc.frac
            y: seekBar.barY
            Rectangle {
                x: -1
                y: -7 * mc.s
                width: seekBar.active ? 3 : 2
                height: 15 * mc.s
                color: Theme.accent
                Behavior on width { NumberAnimation { duration: 120 } }
            }
        }

        MouseArea {
            id: sma
            anchors.fill: parent
            hoverEnabled: true
            preventStealing: true
            cursorShape: Qt.PointingHandCursor
            function local(mx) {
                mc.pos = Math.max(0, Math.min(1, mx / width)) * mc.len   // visual only while dragging
            }
            function commit() {
                if (mc.player?.canSeek) mc.player.position = mc.pos
                mc.base = mc.pos
                mc.baseT = Date.now()
                mc.settleUntil = Date.now() + 2000
                mc.dragging = false
            }
            onPressed: m => { mc.dragging = true; local(m.x) }
            onPositionChanged: m => { if (pressed) local(m.x) }
            onReleased: commit()
            onCanceled: mc.dragging = false
        }
    }
}