import QtQuick
import "../../shared"

Item {
    id: card

    property real s: 1
    property color ink: Theme.fg
    readonly property var player: MediaShared.pickPlayer("")

    implicitHeight: Math.max(art.height, info.height)

    NowPlayingShared { id: now; player: card.player }

    CoverShared {
        id: art
        anchors.verticalCenter: parent.verticalCenter
        width: 104 * card.s
        height: width
        radius: Theme.r(12) * card.s
        glyph: "󰝚"
        url: now.art
    }

    Column {
        id: info
        anchors.left: art.right
        anchors.leftMargin: 14 * card.s
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3 * card.s

        SwapTextShared {
            width: parent.width
            value: card.player ? now.title || "Unknown" : "Nothing playing"
            elide: Text.ElideRight
            font.pixelSize: 15 * card.s
            font.bold: true
            color: card.ink
        }
        SwapTextShared {
            width: parent.width
            value: now.artist
            elide: Text.ElideRight
            font.pixelSize: 12 * card.s
            color: Theme.alpha(card.ink, 0.65)
        }
        SeekShared {
            visible: !!card.player
            width: parent.width
            player: card.player
            u: 0.75 * card.s
            active: card.visible
        }
        Row {
            visible: !!card.player
            spacing: 6 * card.s
            SkipButtonShared { anchors.verticalCenter: parent.verticalCenter; player: card.player; dir: -1; size: 30 * card.s; tint: card.ink }
            PlayButtonShared { anchors.verticalCenter: parent.verticalCenter; player: card.player; size: 32 * card.s }
            SkipButtonShared { anchors.verticalCenter: parent.verticalCenter; player: card.player; dir: 1; size: 30 * card.s; tint: card.ink }
        }
    }
}
