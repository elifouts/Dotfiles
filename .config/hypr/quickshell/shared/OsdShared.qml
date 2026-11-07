import QtQuick
import Quickshell
import Quickshell.Wayland
import "../style/common"

Scope {
    id: root

    property alias active: morph.active
    property alias leaving: morph.leaving
    property alias t: morph.t
    property real pulse: 0
    property real wiggle: 0
    property int fillDuration: 110

    property string kind: "volume"
    property real shownValue: 0

    readonly property real value: OsdStateShared.value(kind)
    readonly property bool flag: OsdStateShared.flag(kind)

    readonly property real dotSize: 52
    readonly property real fullWidth: 300
    readonly property real w: Math.max(0, (t - 0.2) / 0.8)

    readonly property color accent: kind === "volume" ? Theme.info : kind === "brightness" ? Theme.caution : hasBar ? Theme.accent : Theme.accent2

    readonly property bool hasBar: kind === "volume" || kind === "brightness"
    readonly property bool off: kind === "volume" ? flag : false
    readonly property string glyph: {
        switch (kind) {
        case "volume": return flag || shownValue < 0.005 ? "\uf026" : (shownValue < 0.45 ? "\uf027" : "\uf028")
        case "brightness": return "\uf185"
        case "mic": return flag ? "\uf131" : "\uf130"
        case "caps": return flag ? "\uf023" : "\uf09c"
        }
        return ""
    }
    readonly property string title: {
        switch (kind) {
        case "caps": return "Caps Lock"
        case "mic": return "Microphone"
        }
        return ""
    }
    readonly property string readout: {
        if (hasBar) return flag ? "MUTE" : Math.round(shownValue * 100) + "%"
        if (kind === "caps") return flag ? "ON" : "OFF"
        if (kind === "mic") return flag ? "OFF" : "ON"
        return ""
    }
    readonly property bool readoutLit: kind === "caps" ? flag : (kind === "mic" ? !flag : !off)

    MorphShared { id: morph; openMs: 480; closeMs: 340; fadeOut: false }

    Connections {
        target: OsdStateShared
        function onShown(k) { root.present(k) }
        function onMedia(a) { a === "play" ? media.toggle() : media.skip(a === "next" ? 1 : -1) }
    }

    property string wiggleKind: ""
    onFlagChanged: if (active && !leaving && kind === wiggleKind) wiggleAnim.restart()
    onValueChanged: if (active && !leaving) shownValue = value

    function present(k) {
        const fresh = !active || leaving || kind !== k

        kind = k
        wiggleKind = k

        if (fresh) {
            barBehavior.enabled = false
            shownValue = 0
            fillDuration = 420
            barBehavior.enabled = true
        } else {
            fillDuration = 120
        }
        shownValue = value

        hideTimer.restart()
        if (!active || leaving) {
            morph.open()
        } else {
            pulseAnim.restart()
        }

    }

    function hide() { morph.close() }

    Timer { id: hideTimer; interval: 1400; onTriggered: root.hide() }

    SequentialAnimation {
        id: pulseAnim
        NumberAnimation { target: root; property: "pulse"; to: 1; duration: Theme.ms(70); easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "pulse"; to: 0; duration: Theme.ms(220); easing.type: Easing.OutBack }
    }

    SequentialAnimation {
        id: wiggleAnim
        NumberAnimation { target: root; property: "wiggle"; to: -14; duration: Theme.ms(60); easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "wiggle"; to: 11; duration: Theme.ms(90); easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "wiggle"; to: -6; duration: Theme.ms(80); easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "wiggle"; to: 0; duration: Theme.ms(100); easing.type: Easing.OutQuad }
    }

    PanelWindow {
        visible: root.active
        screen: HyprShared.focusedScreen()
        anchors.bottom: true
        margins.bottom: 0
        implicitWidth: 340
        implicitHeight: 156
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "osd"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Item {
            id: card
            width: root.dotSize + (root.fullWidth - root.dotSize) * root.w
            height: root.dotSize
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 76 - 132 * (1 - root.t)
            opacity: Math.min(1, root.t * 8)
            scale: 1 + 0.015 * root.pulse

            Rectangle {
                anchors.fill: parent
                radius: Theme.round * Math.max(10, root.dotSize / 2 - (root.dotSize / 2 - 10) * Math.min(1, root.w))
                color: Theme.back(0.45)
                border.width: Theme.lines
                border.color: Theme.edge
            }

            LabelShared {
                id: icon
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                horizontalAlignment: Text.AlignHCenter
                text: root.glyph
                font.pixelSize: 18
                color: root.off ? Theme.dim : root.accent
                rotation: root.wiggle
                scale: (0.75 + 0.25 * morph.stage(0.1)) * (1 + 0.18 * root.pulse)
                Behavior on color { ColorAnimation { duration: Theme.ms(120) } }
            }

            LabelShared {
                id: readout
                visible: morph.stage(0.55) > 0
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                horizontalAlignment: Text.AlignRight
                text: root.readout
                font.pixelSize: 14
                color: root.readoutLit ? Theme.fg : Theme.dim
                opacity: morph.stage(0.55)
                transform: Translate { x: 6 * (1 - morph.stage(0.55)) }
                Behavior on color { ColorAnimation { duration: Theme.ms(120) } }
            }

            Rectangle {
                visible: root.hasBar && morph.stage(0.5) > 0
                anchors.left: icon.right
                anchors.leftMargin: 14
                anchors.right: readout.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                height: 4
                radius: 2
                color: Theme.alpha(Theme.fg, 0.16)
                opacity: morph.stage(0.5)

                Rectangle {
                    id: fill
                    height: parent.height
                    radius: 2
                    width: parent.width * Math.max(0, Math.min(1, root.shownValue))
                    color: root.off ? Theme.dim : root.accent
                    Behavior on color { ColorAnimation { duration: Theme.ms(90) } }

                    Rectangle {
                        visible: root.shownValue > 0.01 && !root.off
                        anchors.verticalCenter: parent.verticalCenter
                        width: 10 + 6 * root.pulse
                        height: width
                        radius: Theme.round * width / 2
                        x: parent.width - width / 2
                        color: root.accent
                    }
                }
            }

            LabelShared {
                visible: !root.hasBar && morph.stage(0.5) > 0
                anchors.left: icon.right
                anchors.leftMargin: 14
                anchors.right: readout.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: root.title
                elide: Text.ElideRight
                font.pixelSize: 15
                color: Theme.fg
                opacity: morph.stage(0.5)
                transform: Translate { x: -6 * (1 - morph.stage(0.5)) }
            }
        }
    }

    Behavior on shownValue { id: barBehavior; NumberAnimation { duration: Theme.ms(root.fillDuration); easing.type: Easing.OutCubic } }

    Scope {
        id: media

        readonly property var player: MediaShared.pickPlayer("")
        NowPlayingShared { id: now; player: media.player }

        property bool hovered: false
        readonly property real cardW: 340
        readonly property real cardH: 120
        readonly property real dot: 44
        readonly property real side: MediaShared.side === "left" ? 0 : MediaShared.side === "right" ? 1 : 0.5

        MorphShared { id: mm; openMs: 720; closeMs: 560 }

        function toggle() { MediaShared.toggle(player); show() }
        function skip(d) { MediaShared.skip(player, d); show() }
        function show() {
            if (MediaShared.views > 0) return
            hold.interval = 2600
            if (!hovered) hold.restart()
            if (!mm.active || mm.leaving) { mm.closeMs = 560; mm.open() }
        }
        onHoveredChanged: {
            if (hovered) return hold.stop()
            hold.interval = 450
            hold.restart()
        }
        Timer { id: hold; onTriggered: mm.close() }
        Binding { target: MediaShared; property: "card"; value: mm.active && !mm.leaving }
        function leave() { hold.stop(); mm.closeMs = 260; mm.close() }
        Connections {
            target: MediaShared
            function onViewsChanged() { if (MediaShared.views > 0) media.leave() }
            function onDropCard() { media.leave() }
        }

        PanelWindow {
            visible: mm.active
            screen: HyprShared.focusedScreen()
            anchors.top: true
            anchors.left: MediaShared.side === "left"
            anchors.right: MediaShared.side === "right"
            exclusionMode: ExclusionMode.Normal
            implicitWidth: media.cardW + 28
            implicitHeight: media.cardH + 28
            color: "transparent"
            mask: Region { item: mcard }
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "osd"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Item {
                id: mcard
                width: media.dot + (media.cardW - media.dot) * Math.min(1, mm.mw)
                height: 10 + (media.cardH - 10) * Math.min(1, mm.mh)
                x: 14 + (parent.width - 28 - width) * media.side
                y: 6 - (1 - mm.rise) * 18
                opacity: Math.min(1, mm.t * 6)

                HoverHandler { onHoveredChanged: media.hovered = hovered }
                TapHandler { onTapped: { mm.close(); MediaShared.openSpotify() } }

                Rectangle {
                    anchors.fill: parent
                    radius: Math.min(height / 2, Theme.rounding * 1.4)
                    color: Theme.back(0.55)
                    border.width: 1
                    border.color: Theme.lines ? Theme.edge : Theme.alpha(Theme.fg, 0.08)
                }

                Item {
                    anchors.fill: parent
                    clip: true

                    Item {
                        x: (parent.width - width) * media.side
                        width: media.cardW
                        height: media.cardH
                        opacity: mm.leaving ? Math.max(0, Math.min(1, (mm.t - 0.6) / 0.35)) : mm.stage(0.5)

                        CoverShared {
                            id: art
                            x: 12
                            y: 12
                            width: 64
                            height: width
                            radius: Math.min(Theme.rounding, 12)
                            glyph: "\uf001"
                            url: now.art
                        }

                        Column {
                            anchors.left: art.right
                            anchors.leftMargin: 12
                            anchors.right: controls.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: art.verticalCenter
                            spacing: 2

                            LabelShared {
                                width: parent.width
                                text: media.player ? media.player.identity : ""
                                elide: Text.ElideRight
                                font.pixelSize: 10
                                color: Theme.dim
                            }
                            SwapTextShared {
                                width: parent.width
                                value: media.player ? (now.title || "Unknown track") : "Nothing playing"
                                elide: Text.ElideRight
                                font.pixelSize: 14
                                font.bold: true
                                color: Theme.bright
                            }
                            SwapTextShared {
                                width: parent.width
                                visible: value !== ""
                                value: now.artist
                                elide: Text.ElideRight
                                font.pixelSize: 12
                                color: Theme.fg
                            }
                        }

                        Row {
                            id: controls
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: art.verticalCenter
                            SkipButtonShared { anchors.verticalCenter: parent.verticalCenter; player: media.player; dir: -1; size: 32 }
                            PlayButtonShared { anchors.verticalCenter: parent.verticalCenter; player: media.player; size: 36 }
                            SkipButtonShared { anchors.verticalCenter: parent.verticalCenter; player: media.player; dir: 1; size: 32 }
                        }

                        SeekShared {
                            x: 14
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 8
                            width: parent.width - 28
                            player: media.player
                            u: 0.8
                            active: mm.active
                        }
                    }
                }
            }
        }
    }
}
