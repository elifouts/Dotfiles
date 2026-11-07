import QtQuick
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "../../../shared"
import "../../common"

Item {
    id: page

    component Notice: Column {
        id: n
        property string glyph
        property string text
        property string action
        signal pressed()
        anchors.centerIn: parent
        spacing: 10

        LabelShared {
            anchors.horizontalCenter: parent.horizontalCenter
            text: n.glyph
            font.pixelSize: 38
            color: Theme.alpha(Theme.fg, 0.35)
        }
        LabelShared {
            anchors.horizontalCenter: parent.horizontalCenter
            text: n.text
            font.pixelSize: 14
            color: Theme.dim
        }
        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            primary: true
            label: n.action
            onPressed: n.pressed()
        }
    }

    component MediaButton: Text {
        id: b
        property bool ok: true
        property bool on: false
        signal pressed()
        anchors.verticalCenter: parent.verticalCenter
        font.family: Theme.sans
        font.pixelSize: 15
        color: !ok ? Theme.alpha(Theme.fg, 0.2) : on ? Theme.accent : bArea.containsMouse ? Theme.bright : Theme.fg
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        HoverShared {
            id: bArea
            anchors.fill: parent
            anchors.margins: -8
            onClicked: if (b.ok) b.pressed()
        }
    }

    property var player: null
    property var track: null
    property int playerCount: 0
    property bool active: false
    signal cyclePlayer()
    signal popOut()
    signal bringBack()
    property bool musicOut: false
    property bool canPopOut: true
    MediaViewShared { on: page.active }


    function openApp() {
        if (!player || MediaShared.isSpotify(player)) MediaShared.openSpotify()
        else if (player.canRaise) player.raise()
    }

    Notice {
        visible: page.musicOut
        glyph: "󰏌"
        text: "Playing in the music player"
        action: "\uf066  Bring it back"
        onPressed: page.bringBack()
    }

    Notice {
        visible: !page.player && !page.musicOut
        glyph: "󰝚"
        text: "Nothing playing"
        action: "\uf1bc  Open Spotify"
        onPressed: MediaShared.openSpotify()
    }

    Item {
        anchors.fill: parent
        visible: !!page.player && !page.musicOut

        ClippingRectangle {
            id: art
            width: parent.height
            height: width
            radius: Math.min(Theme.rounding, 16)
            color: Theme.alpha(Theme.fg, 0.1)
            scale: artArea.containsMouse ? 1.03 : 1
            Behavior on scale { NumberAnimation { duration: Theme.fast } }

            CoverShared {
                anchors.fill: parent
                radius: art.radius
                fill: "transparent"
                res: 512
                url: page.track?.art ?? ""
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.back(0.45)
                opacity: artArea.containsMouse ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                LabelShared {
                    anchors.centerIn: parent
                    text: "󰏌"
                    font.pixelSize: 20
                    color: Theme.bright
                }
            }

            MouseArea { id: artArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.openApp() }
        }

        Item {
            id: info
            anchors.left: art.right
            anchors.leftMargin: 20
            anchors.right: parent.right
            height: parent.height

            Rectangle {
                id: chip
                height: 20
                width: chipRow.implicitWidth + 16
                radius: Math.min(Theme.rounding, 10)
                color: Theme.alpha(Theme.fg, chipArea.containsMouse && page.playerCount > 1 ? 0.14 : 0.07)

                Row {
                    id: chipRow
                    anchors.centerIn: parent
                    spacing: 6
                    LabelShared {
                        anchors.verticalCenter: parent.verticalCenter
                        text: MediaShared.isSpotify(page.player) ? "" : "󰝚"
                        font.pixelSize: 11
                        color: Theme.ok
                    }
                    LabelShared {
                        anchors.verticalCenter: parent.verticalCenter
                        text: (page.player ? page.player.identity : "") + (page.playerCount > 1 ? "  " : "")
                        font.pixelSize: 10
                        color: Theme.fg
                    }
                }
                MouseArea {
                    id: chipArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: page.playerCount > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: page.cyclePlayer()
                }
            }

            Column {
                y: chip.y + chip.height + (progress.y - chip.y - chip.height - height) / 2
                width: parent.width
                spacing: 2

                SwapTextShared {
                    width: parent.width
                    value: page.player ? (page.track.title || "Unknown title") : ""
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 17
                    font.bold: true
                    color: Theme.bright
                }
                SwapTextShared {
                    width: parent.width
                    value: page.track?.artist ?? ""
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 12
                    color: Theme.fg
                }
                SwapTextShared {
                    width: parent.width
                    visible: value !== ""
                    value: page.track?.album ?? ""
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 11
                    color: Theme.dim
                }
            }

            SeekShared {
                id: progress
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 38
                width: parent.width
                player: page.player
                u: 0.85
                active: page.active
            }
        }

        Rectangle {
            visible: page.canPopOut
            anchors.right: parent.right
            anchors.top: parent.top
            width: 26
            height: 26
            radius: Math.min(Theme.rounding, 8)
            color: Theme.alpha(Theme.fg, popArea.containsMouse ? 0.14 : 0.06)
            Behavior on color { ColorAnimation { duration: Theme.fast } }
            LabelShared {
                anchors.centerIn: parent
                text: "󰏌"
                font.pixelSize: 13
                color: popArea.containsMouse ? Theme.accent : Theme.fg
            }
            MouseArea { id: popArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.popOut() }
        }

        Row {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: info.horizontalCenter
            spacing: 22

            MediaButton {
                text: ""
                ok: !!page.player && page.player.shuffleSupported
                on: ok && page.player.shuffle
                onPressed: page.player.shuffle = !page.player.shuffle
            }
            SkipButtonShared { anchors.verticalCenter: parent.verticalCenter; player: page.player; dir: -1; size: 28; glyphSize: 15 }

            PlayButtonShared { anchors.verticalCenter: parent.verticalCenter; player: page.player; size: 40 }

            SkipButtonShared { anchors.verticalCenter: parent.verticalCenter; player: page.player; dir: 1; size: 28; glyphSize: 15 }
            MediaButton {
                text: page.player && page.player.loopState === MprisLoopState.Track ? "󰑘" : "󰑖"
                ok: !!page.player && page.player.loopSupported
                on: ok && page.player.loopState !== MprisLoopState.None
                onPressed: page.player.loopState = page.player.loopState === MprisLoopState.None ? MprisLoopState.Playlist
                    : page.player.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
            }
        }
    }
}
