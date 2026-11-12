import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../shared"
import "../common"

ShellRoot {
    id: root

    readonly property string uiPath: HyprShared.home + "/.local/state/music-player/ui.json"

    property alias active: morph.active
    property alias leaving: morph.leaving
    property bool tucked: false
    property alias t: morph.t
    property alias targetScreen: morph.screen

    readonly property real u: HyprShared.scaleFor(win.screen)
    readonly property real screenH: win.screen ? win.screen.height : 1080
    readonly property real defaultSide: Math.round(380 * u)
    readonly property real minSide: Math.round(300 * u)
    readonly property real maxSide: Math.max(minSide, Math.round(Math.min(720 * u, screenH * 0.55)))
    property real side: defaultSide
    property real dragSide: defaultSide
    property bool dragging: false
    readonly property real shown: Math.max(minSide, Math.min(maxSide, dragging ? dragSide : side))
    Behavior on side { enabled: !root.dragging; SettleShared { duration: Theme.move } }

    readonly property real k: shown / 380
    function px(v) { return Math.round(v * k) }
    readonly property real pad: px(30)

    readonly property real rounding: Theme.rounding
    readonly property real topGap: Math.max(8, Theme.gapsOut)
    readonly property real radius: Math.min(rounding, shown / 4)

    FileView {
        id: uiFile
        path: root.uiPath
        blockLoading: true
        printErrors: false
    }

    property real offX: 0
    property real offY: 0
    property bool moving: false
    Behavior on offX { enabled: !root.moving; SettleShared { duration: Theme.move } }
    Behavior on offY { enabled: !root.moving; SettleShared { duration: Theme.move } }
    readonly property real homeX: (win.width - shown) / 2
    readonly property real baseX: Math.max(8, Math.min(win.width - shown - 8, homeX + offX))
    readonly property real baseY: Math.max(topGap, Math.min(win.height - shown - 8, topGap + offY))

    function resetPosition() {
        moving = true
        offX = 0
        offY = 0
        moving = false
    }

    readonly property string placement: JSON.stringify({
        open: active && !leaving, tucked: tucked, screen: targetScreen?.name ?? "", side: Math.round(shown), top: topGap,
        x: Math.round(baseX), y: Math.round(baseY)
    })
    onPlacementChanged: placementWrite.restart()
    Timer { id: placementWrite; interval: 30; onTriggered: placementFile.setText(root.placement) }
    FileView {
        id: placementFile
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/music-player.json"
        atomicWrites: false
        printErrors: false
    }

    function saveSide(v) {
        Quickshell.execDetached(["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s\\n" "$2" > "$1"', "sh",
                                 uiPath, JSON.stringify({ side: v / u })])
    }

    readonly property var players: MediaShared.players
    property string pinned: ""
    readonly property var player: MediaShared.pickPlayer(pinned)
    NowPlayingShared { id: now; player: root.player }
    MediaViewShared { on: root.active && !root.leaving }
    readonly property bool spotify: MediaShared.isSpotify(player)
    readonly property bool playing: MediaShared.playing(player)

    function cyclePlayer() {
        const ps = players
        if (!ps || ps.length < 2) return
        const i = ps.indexOf(player)
        pinned = ps[(i + 1) % ps.length].dbusName
    }

    function next() { MediaShared.skip(player, 1) }
    function previous() { MediaShared.skip(player, -1) }
    function toggle() { MediaShared.toggle(player) }
    function seekBy(s) {
        if (!player || !player.canSeek) return
        player.position = Math.max(0, Math.min(player.length, player.position + s))
    }

    function openSpotify() {
        MediaShared.openSpotify()
        close()
    }

    readonly property color volTint: AudioShared.muted ? Theme.along([Theme.bg, Theme.fg], 0.5) : Theme.info

    property real vizIntro: 0

    Component.onCompleted: {
        try {
            const ui = JSON.parse(uiFile.text())
            if (typeof ui.side === "number") side = Math.round(ui.side * u)
        } catch (e) {}
        placementWrite.restart()
        Theme.refresh()
    }

    function show() {
        if (tucked) { untuck(); return }
        if (active && !leaving) return
        Theme.refresh()
        morph.show()
    }

    function begin() {
        if (!active) resetPosition()
        morph.open()
        vizAnim.restart()
        warp.restart()
    }

    Timer {
        id: warp
        interval: 30
        onTriggered: {
            const s = win.screen
            if (!s) return
            const x = Math.round(s.x + root.baseX + root.shown / 2)
            const y = Math.round(s.y + s.height - win.height + root.baseY + root.shown / 2)
            HyprShared.dispatch("hl.dsp.cursor.move({ x = " + x + ", y = " + y + " })", "movecursor " + x + " " + y)
        }
    }

    function close() {
        if (!active || leaving) return
        tucked = false
        morph.close()
    }

    function tuck() {
        if (!active || leaving || tucked) return
        tucked = true
        morph.to(0)
    }

    function untuck() {
        if (!tucked) return
        tucked = false
        if (!active || leaving) return
        morph.to(1)
        vizAnim.restart()
    }

    function toggleOpen() {
        if (active && !leaving) close()
        else show()
    }

    Panel {
        id: morph
        openMs: 400
        closeCurve: Theme.settle
        onClosed: root.vizIntro = 0
        onMoved: root.resetPosition()
        onBegin: root.begin()
    }

    SequentialAnimation {
        id: vizAnim
        PropertyAction { target: root; property: "vizIntro"; value: 0 }
        PauseAnimation { duration: Theme.ms(220) }
        NumberAnimation { target: root; property: "vizIntro"; to: 1; duration: Theme.ms(820); easing.type: Easing.OutQuad }
    }

    IpcHandler {
        target: "music"
        function toggle(): void { root.toggleOpen() }
        function open(): void { root.show() }
        function close(): void { root.close() }
        function tuck(): void { root.tuck() }
        function untuck(): void { root.untuck() }
    }

    PanelWindow {
        id: win
        visible: root.active
        screen: root.targetScreen ?? Quickshell.screens[0]
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Normal
        color: "transparent"
        mask: Region { item: root.active && !root.leaving && !root.tucked ? ld.item : null }
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "music-player"
        WlrLayershell.keyboardFocus: root.active && !root.leaving && !root.tucked
            ? (ld.item && ld.item.hovered ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand) : WlrKeyboardFocus.None

        Loader {
            id: ld
            active: root.active || morph.warm
            focus: true
            sourceComponent: Component {
                Item {
                    id: card
                property alias hovered: hover.hovered
                    width: root.shown
                    height: root.shown * Math.max(0, Math.min(1, root.t))
                    x: root.baseX + (root.shown - width) / 2
                    y: root.baseY
                    opacity: root.active ? Math.min(1, root.t * 8) : 0
                    focus: true

                    HoverHandler { id: hover; onHoveredChanged: if (hovered) card.forceActiveFocus() }

                    Keys.onPressed: event => {
                        const k = event.key
                        if (k === Qt.Key_Escape || k === Qt.Key_Q) root.close()
                        else if (k === Qt.Key_Space || k === Qt.Key_K) root.toggle()
                        else if (k === Qt.Key_Left || k === Qt.Key_H) root.seekBy(-5)
                        else if (k === Qt.Key_Right || k === Qt.Key_L) root.seekBy(5)
                        else if (k === Qt.Key_Up) AudioShared.setVolume(AudioShared.volume + 0.05)
                        else if (k === Qt.Key_Down) AudioShared.setVolume(AudioShared.volume - 0.05)
                        else if (k === Qt.Key_M) AudioShared.toggleMute()
                        else if (k === Qt.Key_N || k === Qt.Key_Period) root.next()
                        else if (k === Qt.Key_P || k === Qt.Key_Comma) root.previous()
                        else { event.accepted = false; return }
                        event.accepted = true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: pressed && root.moving ? Qt.ClosedHandCursor : Qt.ArrowCursor
                        property point start
                        property real sx: 0
                        property real sy: 0

                        function at(mouse) {
                            return mapToItem(win.contentItem, mouse.x, mouse.y)
                        }

                        onPressed: mouse => {
                            card.forceActiveFocus()
                            start = at(mouse)
                            sx = root.baseX - root.homeX
                            sy = root.baseY - root.topGap
                        }
                        onPositionChanged: mouse => {
                            if (!pressed || !root.active || root.leaving) return
                            const p = at(mouse)
                            if (!root.moving && Math.hypot(p.x - start.x, p.y - start.y) < 4) return
                            root.moving = true
                            root.offX = sx + p.x - start.x
                            root.offY = sy + p.y - start.y
                        }
                        onReleased: {
                            if (!root.moving) return
                            root.offX = root.baseX - root.homeX
                            root.offY = root.baseY - root.topGap
                            root.moving = false
                        }
                        onDoubleClicked: { root.offX = 0; root.offY = 0 }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Math.min(card.height / 2, root.radius)
                        color: Theme.panel
                        border.width: 1
                        border.color: Theme.edge
                    }

                    Item {
                        anchors.fill: parent
                        clip: true

                        Item {
                            width: root.shown - root.pad * 2
                            height: root.shown - root.pad * 2
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: root.pad

                            Item {
                                id: topRow
                                width: parent.width
                                height: root.px(26)
                                opacity: morph.stage(0.55)
                                transform: Translate { y: -8 * (1 - morph.stage(0.5)) }

                                Rectangle {
                                    visible: !!root.player
                                    height: parent.height
                                    width: chipRow.implicitWidth + root.px(20)
                                    radius: height / 2
                                    color: Theme.alpha(Theme.fg, chipArea.containsMouse && root.players.length > 1 ? 0.12 : 0.06)
                                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                                    Behavior on width { SettleShared { duration: Theme.move } }

                                    Row {
                                        id: chipRow
                                        anchors.centerIn: parent
                                        spacing: root.px(7)

                                        Rectangle {
                                            id: liveDot
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: root.px(6)
                                            height: width
                                            radius: width / 2
                                            color: root.playing ? Theme.ok : Theme.dim
                                            Behavior on color { ColorAnimation { duration: Theme.move } }
                                            SequentialAnimation on opacity {
                                                running: root.active && root.playing
                                                loops: Animation.Infinite
                                                onRunningChanged: if (!running) liveDot.opacity = 1
                                                NumberAnimation { to: 0.35; duration: 900; easing.type: Easing.InOutSine }
                                                NumberAnimation { to: 1; duration: 900; easing.type: Easing.InOutSine }
                                            }
                                        }
                                        LabelShared {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: root.player ? (root.player.identity || "Player") : ""
                                            font.pixelSize: root.px(11)
                                            color: Theme.fg
                                        }
                                        LabelShared {
                                            visible: root.players.length > 1
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: ""
                                            font.pixelSize: root.px(9)
                                            color: Theme.dim
                                        }
                                    }

                                    MouseArea {
                                        id: chipArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: root.players.length > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: root.cyclePlayer()
                                    }
                                }

                                Glyph {
                                    id: spotifyButton
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    size: root.px(30)
                                    glyph: ""
                                    glyphSize: root.px(19)
                                    tint: root.spotify ? Theme.ok : Theme.fg
                                    onClicked: root.openSpotify()
                                }

                                Volume {
                                    anchors.right: spotifyButton.left
                                    anchors.rightMargin: root.px(8)
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: root.px(116)
                                }
                            }

                            Item {
                                anchors.top: topRow.bottom
                                anchors.topMargin: root.px(22)
                                width: parent.width
                                height: root.px(100)
                                opacity: morph.stage(0.6)
                                transform: Translate { y: 10 * (1 - morph.stage(0.55)) }

                                CoverShared {
                                    id: art
                                    width: parent.height
                                    height: parent.height
                                    radius: root.px(12)
                                    glyph: ""
                                    url: now.art
                                }

                                Item {
                                    id: info
                                    anchors.left: art.right
                                    anchors.leftMargin: root.px(18)
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: infoCol.implicitHeight

                                    Column {
                                        id: infoCol
                                        width: parent.width
                                        spacing: root.px(4)

                                        SwapTextShared {
                                            width: parent.width
                                            value: root.player ? (now.title || "Unknown track") : "Nothing playing"
                                            elide: Text.ElideRight
                                            font.pixelSize: root.px(17)
                                            color: Theme.bright
                                        }
                                        SwapTextShared {
                                            width: parent.width
                                            visible: value !== ""
                                            value: root.player ? now.artist : "Open Spotify to start"
                                            elide: Text.ElideRight
                                            font.pixelSize: root.px(13)
                                            color: Theme.fg
                                        }
                                        SwapTextShared {
                                            width: parent.width
                                            visible: value !== ""
                                            value: root.player ? now.album : ""
                                            elide: Text.ElideRight
                                            font.pixelSize: root.px(11)
                                            color: Theme.dim
                                        }
                                    }
                                }
                            }

                            Visualizer {
                                id: viz
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: root.px(34)
                                running: root.active || morph.hopping
                                intro: root.vizIntro
                                opacity: morph.stage(0.7)
                            }

                            Item {
                                id: controls
                                anchors.bottom: viz.top
                                anchors.bottomMargin: root.px(18)
                                width: parent.width
                                height: root.px(56)
                                opacity: morph.stage(0.66)
                                transform: Translate { y: 8 * (1 - morph.stage(0.62)) }
                                enabled: !!root.player

                                SkipButtonShared {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.right: playButton.left
                                    anchors.rightMargin: root.px(26)
                                    player: root.player
                                    dir: -1
                                    size: root.px(44)
                                    glyphSize: root.px(16)
                                }

                                PlayButtonShared {
                                    id: playButton
                                    anchors.centerIn: parent
                                    player: root.player
                                    size: root.px(56)
                                }

                                SkipButtonShared {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: playButton.right
                                    anchors.leftMargin: root.px(26)
                                    player: root.player
                                    dir: 1
                                    size: root.px(44)
                                    glyphSize: root.px(16)
                                }
                            }

                            SeekShared {
                                player: root.player
                                u: root.k
                                active: root.active
                                anchors.bottom: controls.top
                                anchors.bottomMargin: root.px(10)
                                width: parent.width
                                opacity: morph.stage(0.63)
                                transform: Translate { y: 8 * (1 - morph.stage(0.6)) }
                            }
                        }
                    }

                    Item {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: root.px(90)
                        height: root.px(16)
                        opacity: morph.stage(0.75)

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: root.px(7)
                            height: 4
                            width: grabArea.containsMouse || grabArea.pressed ? root.px(64) : root.px(36)
                            radius: 2
                            color: Theme.alpha(grabArea.containsMouse || grabArea.pressed ? Theme.accent : Theme.fg, grabArea.containsMouse || grabArea.pressed ? 0.85 : 0.18)
                            Behavior on width { NumberAnimation { duration: Theme.ms(200); easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: Theme.fast } }
                        }

                        MouseArea {
                            id: grabArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.SizeVerCursor
                            preventStealing: true

                            property real startY: 0
                            property real startSide: 0

                            function windowY(mouse) {
                                return mapToItem(win.contentItem, mouse.x, mouse.y).y
                            }

                            onPressed: mouse => {
                                startY = windowY(mouse)
                                startSide = root.shown
                                root.dragSide = root.shown
                                root.dragging = true
                            }
                            onPositionChanged: mouse => {
                                if (!pressed) return
                                const want = startSide + (windowY(mouse) - startY)
                                const lo = root.minSide, hi = root.maxSide
                                root.dragSide = want < lo ? lo - Math.sqrt(lo - want) * 2
                                              : want > hi ? hi + Math.sqrt(want - hi) * 2 : want
                            }
                            onReleased: {
                                root.side = Math.max(root.minSide, Math.min(root.maxSide, root.dragSide))
                                root.dragging = false
                                let next = root.side
                                if (Math.abs(next - root.defaultSide) < 14) next = root.defaultSide
                                root.side = next
                                root.saveSide(next)
                            }
                        }
                    }
                }
            }
        }
    }

    component Glyph: Item {
        id: btn
        property real size: 40
        property string glyph: ""
        property real glyphSize: 16
        property color tint: Theme.fg
        property bool dimmed: false
        property real kick: 0
        signal clicked()

        width: size
        height: size

        function bump() { kickAnim.restart() }

        SequentialAnimation {
            id: kickAnim
            NumberAnimation { target: btn; property: "kick"; to: 1; duration: Theme.ms(90); easing.type: Easing.OutQuad }
            NumberAnimation { target: btn; property: "kick"; to: 0; duration: Theme.ms(380); easing.type: Easing.OutBack; easing.overshoot: 2.2 }
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Theme.alpha(Theme.fg, area.pressed ? 0.16 : 0.09)
            opacity: area.containsMouse && !btn.dimmed ? 1 : 0
            scale: area.containsMouse ? 1 : 0.7
            Behavior on opacity { NumberAnimation { duration: Theme.fast } }
            Behavior on scale { SettleShared { duration: Theme.move } }
        }

        LabelShared {
            anchors.centerIn: parent
            text: btn.glyph
            font.pixelSize: btn.glyphSize
            color: btn.dimmed ? Theme.dim : (area.containsMouse ? Theme.bright : btn.tint)
            opacity: btn.dimmed ? 0.5 : 1
            scale: (area.pressed ? 0.84 : 1) * (1 + 0.08 * btn.kick)
            Behavior on color { ColorAnimation { duration: Theme.fast } }
            Behavior on scale { NumberAnimation { duration: Theme.ms(180); easing.type: Easing.OutBack; easing.overshoot: 2 } }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: btn.dimmed ? Qt.ArrowCursor : Qt.PointingHandCursor
            onClicked: {
                if (btn.dimmed) return
                btn.bump()
                btn.clicked()
            }
        }
    }

    component Volume: Item {
        id: vb
        height: root.px(24)
        readonly property real level: AudioShared.muted ? 0 : AudioShared.volume

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Theme.alpha(Theme.fg, volDrag.containsMouse || volDrag.pressed ? 0.14 : 0.08)
            clip: true
            Behavior on color { ColorAnimation { duration: Theme.fast } }

            Rectangle {
                height: parent.height
                width: Math.max(parent.height, parent.width * vb.level)
                radius: height / 2
                color: Theme.soft(root.volTint)
                Behavior on width { enabled: !volDrag.pressed; NumberAnimation { duration: Theme.ms(120); easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: Theme.fast } }
            }
        }

        LabelShared {
            x: root.px(8)
            anchors.verticalCenter: parent.verticalCenter
            text: AudioShared.muted || AudioShared.volume === 0 ? "\uf026" : "\uf028"
            font.pixelSize: root.px(12)
            color: Theme.on(root.volTint)
        }

        LabelShared {
            anchors.right: parent.right
            anchors.rightMargin: root.px(9)
            anchors.verticalCenter: parent.verticalCenter
            text: AudioShared.muted ? "Muted" : Math.round(AudioShared.volume * 100) + "%"
            font.pixelSize: root.px(10)
            color: vb.level > 0.8 ? Theme.on(root.volTint) : Theme.fg
        }

        HoverShared {
            id: volDrag
            anchors.fill: parent
            preventStealing: true
            onPressed: mouse => AudioShared.setVolume(mouse.x / width)
            onPositionChanged: mouse => { if (pressed) AudioShared.setVolume(mouse.x / width) }
            onWheel: wheel => AudioShared.setVolume(AudioShared.volume + wheel.angleDelta.y / 120 * 0.03)
        }
        MouseArea {
            width: parent.height
            height: parent.height
            cursorShape: Qt.PointingHandCursor
            onClicked: AudioShared.toggleMute()
        }
    }
}
