import QtQuick
import "../../shared"

Item {
    id: card
    property real s: 1
    property color ink: Theme.fg
    readonly property var player: MediaShared.pickPlayer("")
    implicitHeight: Math.max(art.height, info.height)

    NowPlayingShared { id: now; player: card.player }
    SeekShared { id: seek; opacity: 0; enabled: false; width: 0; height: 0; player: card.player; active: card.visible }

    CoverShared {
        id: art
        anchors.verticalCenter: parent.verticalCenter
        width: 92 * card.s
        height: width
        radius: 0
        fill: Theme.low
        glyph: "󰝚"
        glyphColor: Theme.accent
        url: now.art
        Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: Theme.line }
    }

    Column {
        id: info
        anchors.left: art.right
        anchors.leftMargin: 12 * card.s
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2 * card.s

        Type { width: parent.width; caps: false; text: card.player ? now.title || "unknown" : "no signal"; elide: Text.ElideRight; font.pixelSize: (Theme.size + 2) * card.s; color: card.player ? Theme.accent : Theme.dim }
        Type { width: parent.width; caps: false; text: card.player ? now.artist : "open spotify"; elide: Text.ElideRight; font.pixelSize: Theme.size * card.s; color: card.ink
            HoverShared { anchors.fill: parent; enabled: !card.player; onClicked: MediaShared.openSpotify() } }
        Item {
            visible: !!card.player
            width: parent.width
            height: 20 * card.s
            Slider {
                id: bar
                width: parent.width - time.width - 8
                height: parent.height
                scrollable: false
                value: seek.frac
                onMoved: v => { if (seek.live) card.player.position = v * seek.length }
            }
            Type { id: time; type: false; anchors.right: parent.right; height: parent.height; text: seek.clock(seek.position) + "/" + seek.clock(seek.length); font.pixelSize: (Theme.size - 2) * card.s; color: Theme.dim }
        }
        Row {
            visible: !!card.player
            spacing: 6 * card.s
            Repeater {
                model: [["|◀", () => MediaShared.skip(card.player, -1)], [MediaShared.playing(card.player) ? "▌▌" : " ▶ ", () => MediaShared.toggle(card.player)], ["▶|", () => MediaShared.skip(card.player, 1)]]
                Button {
                    required property var modelData
                    label: modelData[0]
                    height: 22 * card.s
                    onPressed: modelData[1]()
                }
            }
        }
    }
}
