import QtQuick
import Quickshell
import "../../shared"

Column {
    id: mc
    spacing: 10 * s
    width: parent?.width ?? 300
    property real s: 1
    property color ink: Theme.fg

    readonly property var player: MediaShared.players.find(p => MediaShared.isSpotify(p))
        ?? MediaShared.players.find(p => p.isPlaying)
        ?? null
    readonly property bool playing: MediaShared.playing(player)

    Item {
        width: mc.width
        height: 100 * mc.s
        visible: !mc.player

        Column {
            anchors.centerIn: parent
            spacing: 8 * mc.s

            Say {
                font.capitalization: Theme.caps
                font.letterSpacing: Theme.tracking
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰝚"
                font.pixelSize: 26 * mc.s
                color: Theme.accent
            }

            Say {
                font.capitalization: Theme.caps
                font.letterSpacing: Theme.tracking
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Nothing playing"
                font.pixelSize: 12 * mc.s
                color: Theme.dim
            }

            Say {
                font.capitalization: Theme.caps
                font.letterSpacing: Theme.tracking
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Open Spotify"
                font.pixelSize: 10 * mc.s
                color: Theme.accent

                HoverShared {
                    anchors.fill: parent
                    onClicked: MediaShared.openSpotify()
                }
            }
        }
    }

    readonly property real len: Math.max(1, player?.length ?? 1)
    NowPlayingShared { id: now; player: mc.player; visible: !!mc.player }

    property real base: 0
    property real baseT: Date.now()
    property real pos: 0
    property bool dragging: false
    property real settleUntil: 0
    property real frac: 0

    function refrac() { frac = Math.max(0, Math.min(1, pos / len)) }
    onPosChanged: refrac()
    onLenChanged: refrac()

    function rebase(p) { base = p; baseT = Date.now(); pos = p }

    function sync() {
        player?.positionChanged()
        rebase(player?.position ?? 0)
    }

    function fmt(t) {
        t = Math.max(0, Math.floor(t))
        const m = Math.floor(t / 60), r = t % 60
        return String(m).padStart(2, "0") + ":" + String(r).padStart(2, "0")
    }

    onPlayingChanged: sync()
    onPlayerChanged: sync()
    Connections { target: now; function onTitleChanged() { mc.sync() } }

    readonly property bool ticking: visible && playing && !dragging

    Timer {
        running: mc.ticking
        interval: 250
        repeat: true
        onTriggered: mc.pos = Math.min(mc.len, mc.base + (Date.now() - mc.baseT) / 1000)
    }

    Timer {
        running: mc.ticking
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (Date.now() < mc.settleUntil) return
            mc.player?.positionChanged()
            const p = mc.player?.position ?? 0
            if (Math.abs(p - mc.pos) > 0.5) mc.rebase(p)
        }
    }

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
                    duration: Theme.ms(ma.pressed ? 70 : 240)
                    easing.type: ma.pressed ? Easing.OutQuad : Easing.OutBack
                }
            }

            Rectangle {
                anchors.fill: parent
                visible: b.primary
                color: Theme.alpha(Theme.accent, ma.pressed ? 0.28 : (ma.containsMouse ? 0.16 : 0.08))
                border.width: 1
                border.color: Theme.alpha(Theme.accent, ma.containsMouse ? 0.9 : 0.4)
                Behavior on color { ColorAnimation { duration: Theme.fast } }
                Behavior on border.color { ColorAnimation { duration: Theme.fast } }
            }

            Text {
                anchors.centerIn: parent
                text: b.glyph
                font.family: Theme.sans
                font.pixelSize: (b.primary ? 20 : 15) * b.s
                color: ma.containsMouse ? Theme.accent : b.ink
                Behavior on color { ColorAnimation { duration: Theme.fast } }
            }
        }

        HoverShared {
            id: ma
            anchors.fill: parent
            onClicked: b.clicked()
        }
    }

    Row {
        visible: !!mc.player
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 12 * mc.s

        Rectangle {
            width: 52 * mc.s
            height: width
            color: Theme.alpha(Theme.accent, 0.12)
            border.width: 1
            border.color: Theme.alpha(Theme.accent, 0.4)

            Image {
                anchors.fill: parent
                anchors.margins: 1
                source: now.art
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(width, height)
                asynchronous: true
            }

            Text {
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                visible: !now.art
                text: "󰎈"
                font.family: Theme.sans
                font.pixelSize: 20 * mc.s
                color: Theme.accent
            }
        }

        Column {
            width: Math.min(mc.width - 64 * mc.s, Math.max(who.implicitWidth, title.implicitWidth, artist.implicitWidth))
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Say {
                font.capitalization: Theme.caps
                font.letterSpacing: Theme.tracking
                id: who
                text: mc.player ? mc.player.identity : "nothing playing"
                font.pixelSize: 9 * mc.s
                color: Theme.dim
            }

            Say {
                id: title
                width: parent.width
                text: now.title || "—"
                elide: Text.ElideRight
                font.pixelSize: 14 * mc.s
                color: mc.ink
            }

            Say {
                id: artist
                width: parent.width
                visible: text !== ""
                text: [now.artist, now.album].filter(Boolean).join("  ·  ")
                elide: Text.ElideRight
                font.pixelSize: 11 * mc.s
                color: Theme.alpha(mc.ink, 0.65)
            }
        }
    }

    Row {
        visible: !!mc.player
        spacing: 6 * mc.s
        anchors.horizontalCenter: parent.horizontalCenter

        Btn {
            glyph: "󰒮"; s: mc.s; ink: mc.ink
            anchors.verticalCenter: parent.verticalCenter
            enabled: !!mc.player
            onClicked: MediaShared.skip(mc.player, -1)
        }

        Btn {
            glyph: mc.playing ? "󰏤" : "󰐊"; primary: true; s: mc.s; ink: mc.ink
            anchors.verticalCenter: parent.verticalCenter
            enabled: !!mc.player
            onClicked: MediaShared.toggle(mc.player)
        }

        Btn {
            glyph: "󰒭"; s: mc.s; ink: mc.ink
            anchors.verticalCenter: parent.verticalCenter
            enabled: !!mc.player
            onClicked: MediaShared.skip(mc.player, 1)
        }
    }

    Item {
        id: seekBar
        width: parent.width
        height: 34 * mc.s
        visible: !!mc.player && (mc.player?.length ?? 0) > 0
        readonly property bool active: sma.containsMouse || mc.dragging
        readonly property int ticks: Math.max(16, Math.round(width / (6 * mc.s)))
        readonly property real barY: 24 * mc.s

        LabelShared {
            anchors.left: parent.left
            anchors.top: parent.top
            text: mc.fmt(mc.pos)
            font.pixelSize: 9 * mc.s
            font.letterSpacing: 1.5
            color: Theme.accent
        }

        LabelShared {
            anchors.right: parent.right
            anchors.top: parent.top
            text: "-" + mc.fmt(mc.len - mc.pos)
            font.pixelSize: 9 * mc.s
            font.letterSpacing: 1.5
            color: Theme.dim
        }

        LabelShared {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            text: Math.round(mc.frac * 100) + "%"
            font.pixelSize: 9 * mc.s
            font.letterSpacing: 1.5
            color: Theme.alpha(mc.ink, seekBar.active ? 0.7 : 0.3)
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }

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

        Rectangle { x: 0; y: seekBar.barY; width: parent.width; height: 1; color: Theme.faint }
        Rectangle { x: 0; y: seekBar.barY - 4 * mc.s; width: 1; height: 9 * mc.s; color: Theme.alpha(Theme.accent, 0.6) }
        Rectangle { x: parent.width - 1; y: seekBar.barY - 4 * mc.s; width: 1; height: 9 * mc.s; color: Theme.alpha(Theme.accent, 0.6) }

        Rectangle {
            x: 0
            y: seekBar.barY - 2 * mc.s
            width: parent.width * mc.frac
            height: 5 * mc.s
            color: Theme.alpha(Theme.accent, seekBar.active ? 0.28 : 0.16)
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }

        Rectangle {
            x: 0
            y: seekBar.barY
            width: parent.width * mc.frac
            height: 1
            color: Theme.accent
        }

        Item {
            x: parent.width * mc.frac
            y: seekBar.barY

            Rectangle {
                x: -1
                y: -7 * mc.s
                width: seekBar.active ? 3 : 2
                height: 15 * mc.s
                color: Theme.accent
                Behavior on width { SettleShared { duration: Theme.ms(120) } }
            }
        }

        MouseArea {
            id: sma
            anchors.fill: parent
            hoverEnabled: true
            preventStealing: true
            cursorShape: Qt.PointingHandCursor

            function local(mx) {
                mc.pos = Math.max(0, Math.min(1, mx / width)) * mc.len
            }

            function commit() {
                if (mc.player?.canSeek) mc.player.position = mc.pos
                mc.rebase(mc.pos)
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

