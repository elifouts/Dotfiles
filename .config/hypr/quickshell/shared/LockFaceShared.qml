import QtQuick
import QtQuick.Effects
import Quickshell
import "../style/common"

Item {
    id: face

    component Card: Rectangle {
        property real u: 1
        radius: Theme.rounding * u
        color: LockShared.card
        border.width: 1
        border.color: LockShared.edge
    }

    component Wave: Row {
        id: wave

        property bool playing: false
        property real u: 1
        readonly property int bars: 10
        readonly property var levels: feed.levels

        spacing: 2 * u

        CavaFeedShared { id: feed; running: wave.playing; bars: wave.bars; framerate: 60 }

        Repeater {
            model: wave.bars

            Rectangle {
                required property int index
                readonly property real level: wave.playing ? (wave.levels[index] || 0) : 0

                anchors.verticalCenter: parent.verticalCenter
                width: 2.5 * wave.u
                height: Math.max(4, Math.round((3 + level * 12) * wave.u / 2) * 2)
                radius: width / 2
                color: Theme.along(Theme.spectrum, index / (wave.bars - 1))
                opacity: wave.playing ? 0.35 + 0.65 * level : 0.45

                Behavior on height { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                Behavior on opacity { NumberAnimation { duration: 100 } }
            }
        }
    }

    component RoundButton: Item {
        id: b

        property string glyph
        property real u: 1
        property real size: 44 * u
        property color tint: LockShared.ink
        property bool filled: false
        property bool armed: false
        signal clicked()

        width: size
        height: size
        scale: area.pressed ? 0.9 : area.containsMouse ? 1.06 : 1
        Behavior on scale { SettleShared { duration: Theme.ms(220) } }

        Card {
            anchors.fill: parent
            radius: LockShared.corner(b.size, b.u)
            opacity: b.filled || b.armed ? 0 : 1
        }
        Rectangle {
            anchors.fill: parent
            radius: LockShared.corner(b.size, b.u)
            color: Theme.soft(b.armed ? Theme.warn : Theme.accent, area.containsMouse)
            opacity: b.filled || b.armed ? 1 : area.containsMouse ? 0.12 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.ms(160) } }
            Behavior on color { ColorAnimation { duration: Theme.ms(160) } }
        }

        LabelShared {
            anchors.centerIn: parent
            text: b.glyph
            font.pixelSize: b.size * 0.4
            color: b.filled || b.armed ? Theme.on(b.armed ? Theme.warn : Theme.accent) : b.tint
            Behavior on color { ColorAnimation { duration: Theme.ms(160) } }
        }

        HoverShared {
            id: area
            anchors.fill: parent
            onClicked: b.clicked()
        }
    }

    component Reveal: Item {
        id: r

        property real delay: 0
        property bool on: true
        property real u: 1
        default property alias content: body.data

        readonly property real p: Theme.seg(LockShared.t, delay)
        property real shown: on ? 1 : 0
        Behavior on shown { SettleShared { duration: Theme.ms(420) } }

        implicitWidth: body.childrenRect.width
        implicitHeight: body.childrenRect.height * shown
        opacity: p * shown * (1 - LockShared.out)
        visible: opacity > 0.001
        scale: (0.96 + 0.04 * p) * (1 - 0.03 * LockShared.out)
        transform: Translate { y: (1 - r.p) * 26 * r.u + (1 - r.shown) * -8 * r.u + LockShared.out * 14 * r.u }

        Item {
            id: body
            width: childrenRect.width
            height: childrenRect.height
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    component Art: Item {
        property real u: 1
        property int res: 256
        CoverShared {
            id: cover
            anchors.fill: parent
            radius: LockShared.corner(width, parent.u)
            fill: Theme.alpha(Theme.info, 0.12)
            glyph: ""
            glyphColor: Theme.info
            res: parent.res
            url: LockShared.track.art
        }
        Rectangle {
            anchors.fill: parent
            visible: Theme.lines > 0
            radius: cover.radius
            color: "transparent"
            border.width: Theme.lines
            border.color: Theme.edge
        }
    }

    component Digit: Item {
        id: d

        property string value
        property real size: 100
        property color color: LockShared.ink
        property int weight: Font.Light
        property string cur: value

        width: cell.advanceWidth * Math.max(1, value.length)
        height: label.implicitHeight

        TextMetrics { id: cell; font: label.font; text: "0" }

        LabelShared {
            id: label
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            text: d.cur
            font.pixelSize: d.size
            font.weight: d.weight
            color: d.color
        }

        onValueChanged: if (value !== cur) flip.restart()

        SequentialAnimation {
            id: flip
            ParallelAnimation {
                NumberAnimation { target: label; property: "y"; to: -d.size * 0.22; duration: Theme.ms(180); easing.type: Easing.InCubic }
                NumberAnimation { target: label; property: "opacity"; to: 0; duration: Theme.ms(180) }
            }
            ScriptAction { script: { d.cur = d.value; label.y = d.size * 0.22 } }
            ParallelAnimation {
                SettleShared { target: label; property: "y"; to: 0; duration: Theme.ms(420) }
                NumberAnimation { target: label; property: "opacity"; to: 1; duration: Theme.ms(300) }
            }
        }
    }

    property string screenName
    readonly property bool portrait: height > width
    readonly property real u: portrait
        ? Math.max(0.6, Math.min(width / 760, height / 1350))
        : Math.max(0.6, Math.min(width / 1600, height / 900))

    readonly property bool main: screenName === (LockShared.lockedOn || (Quickshell.screens[0] || {}).name)
    readonly property bool awake: !LockShared.idle
    readonly property real margin: 32 * u

    opacity: LockShared.preview ? LockShared.fade : 1

    Rectangle { anchors.fill: parent; color: "black" }

    Item {
        anchors.fill: parent
        scale: 1 + 0.035 * LockShared.t

        Image {
            id: shot
            anchors.fill: parent
            source: face.screenName ? "file://" + LockShared.shots + "/" + face.screenName + ".ppm" : ""
            fillMode: Image.PreserveAspectCrop
            cache: false
            asynchronous: false
        }
        MultiEffect {
            anchors.fill: parent
            source: shot
            visible: shot.status === Image.Ready
            opacity: Math.max(0.001, Math.min(1, LockShared.t * 2.2))
            blurEnabled: true
            blurMax: 64
            blur: 1
            autoPaddingEnabled: false
        }
    }
    Backdrop {
        anchors.fill: parent
        t: LockShared.t
        source: LockShared.wallpaper
        opacity: Math.max(0.001, shot.status === Image.Ready ? Math.min(1, (LockShared.t - 0.2) * 1.8) : 1)
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: LockShared.poke()
        onClicked: { LockShared.menuOpen = false; input.forceActiveFocus() }
    }

    TextInput {
        id: input
        width: 0
        height: 0
        opacity: 0
        focus: true
        echoMode: TextInput.Password
        text: LockShared.password
        onTextEdited: { LockShared.password = text; LockShared.failed = false; LockShared.poke() }
        onAccepted: LockShared.submit()
        Keys.onPressed: event => {
            LockShared.poke()
            LockShared.checkCaps()
            if (event.key === Qt.Key_Escape) {
                if (LockShared.menuOpen) LockShared.menuOpen = false
                else if (LockShared.preview && LockShared.password === "") LockShared.leave()
                else LockShared.password = ""
                event.accepted = true
            }
        }
        Component.onCompleted: forceActiveFocus()
        Connections {
            target: LockShared
            function onMenuOpenChanged() { if (!LockShared.menuOpen) input.forceActiveFocus() }
        }
    }

    SystemClock { id: clock; precision: SystemClock.Seconds }

    Reveal {
        x: face.margin
        y: face.margin
        delay: 0.1
        on: face.main && LockShared.cfg.greeter && face.awake
        u: face.u
        LabelShared {
            text: "Hello, <b>" + LockShared.user + "</b>"
            textFormat: Text.StyledText
            font.pixelSize: 22 * face.u
            font.capitalization: Theme.caps
            font.letterSpacing: Theme.tracking * face.u
            color: LockShared.ink
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: (face.main && face.portrait ? -140 : -30) * face.u

        Reveal {
            anchors.horizontalCenter: parent.horizontalCenter
            delay: 0.02
            on: LockShared.cfg.clock && face.main
            u: face.u

            Column {
                Row {
                    id: clockRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    readonly property real size: 150 * face.u
                    readonly property string hh: String(Theme.h24 ? clock.hours : clock.hours % 12 || 12).padStart(2, "0")
                    readonly property string mm: String(clock.minutes).padStart(2, "0")

                    Digit { value: clockRow.hh[0]; size: clockRow.size }
                    Digit { value: clockRow.hh[1]; size: clockRow.size }
                    LabelShared {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -clockRow.size * 0.06
                        text: ":"
                        font.pixelSize: clockRow.size * 0.9
                        font.weight: Font.Light
                        color: Theme.accent
                    }
                    Digit { value: clockRow.mm[0]; size: clockRow.size }
                    Digit { value: clockRow.mm[1]; size: clockRow.size }
                    Row {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: clockRow.size * 0.2
                        leftPadding: 10 * face.u
                        readonly property string ss: String(clock.seconds).padStart(2, "0")
                        Digit { value: parent.ss[0]; size: clockRow.size * 0.26; color: Theme.accent2; weight: Font.Normal }
                        Digit { value: parent.ss[1]; size: clockRow.size * 0.26; color: Theme.accent2; weight: Font.Normal }
                    }
                }
                LabelShared {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(clock.date, Theme.lines ? "ddd  ·  d MMM" : "dddd, d MMMM")
                    font.pixelSize: 24 * face.u
                    font.capitalization: Theme.caps
                    font.letterSpacing: Theme.tracking * face.u
                    color: Theme.alpha(LockShared.ink, 0.8)
                }
            }
        }

        Item { width: 1; height: (face.main ? 56 : 0) * face.u }

        Reveal {
            anchors.horizontalCenter: parent.horizontalCenter
            delay: 0.16
            on: face.main && (face.awake || LockShared.password !== "")
            u: face.u

            Item {
                id: field
                readonly property real h: 54 * face.u
                readonly property bool typing: LockShared.password !== ""
                width: typing ? dots.width + h + 22 * face.u : h
                height: h
                Behavior on width { SettleShared { duration: Theme.ms(300) } }

                transform: Translate { id: shakeX }
                SequentialAnimation {
                    id: shake
                    NumberAnimation { target: shakeX; property: "x"; to: 14 * face.u; duration: Theme.ms(50); easing.type: Easing.OutQuad }
                    NumberAnimation { target: shakeX; property: "x"; to: -11 * face.u; duration: Theme.ms(90); easing.type: Easing.InOutQuad }
                    NumberAnimation { target: shakeX; property: "x"; to: 7 * face.u; duration: Theme.ms(80); easing.type: Easing.InOutQuad }
                    NumberAnimation { target: shakeX; property: "x"; to: -3 * face.u; duration: Theme.ms(70); easing.type: Easing.InOutQuad }
                    NumberAnimation { target: shakeX; property: "x"; to: 0; duration: Theme.ms(60); easing.type: Easing.OutQuad }
                }
                Connections {
                    target: LockShared
                    function onRejected() { shake.restart() }
                }

                Card {
                    anchors.fill: parent
                    radius: LockShared.corner(field.h, face.u)
                }
                Rectangle {
                    anchors.fill: parent
                    radius: LockShared.corner(field.h, face.u)
                    color: "transparent"
                    border.width: 1.5 * face.u
                    border.color: LockShared.failed ? Theme.warn : Theme.accent
                    opacity: LockShared.failed ? 1 : field.typing ? 0.5 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.ms(200) } }
                    Behavior on border.color { ColorAnimation { duration: Theme.ms(200) } }
                }

                LabelShared {
                    x: (field.h - width) / 2
                    anchors.verticalCenter: parent.verticalCenter
                    text: ""
                    font.pixelSize: 19 * face.u
                    color: LockShared.failed ? Theme.warn : field.typing ? Theme.accent : LockShared.ink
                    Behavior on color { ColorAnimation { duration: Theme.ms(200) } }
                }

                Row {
                    id: dots
                    x: field.h - 4 * face.u
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8 * face.u
                    Repeater {
                        model: Math.min(LockShared.password.length, 24)
                        Rectangle {
                            id: dot
                            required property int index
                            anchors.verticalCenter: parent.verticalCenter
                            width: 10 * face.u
                            height: width
                            radius: width / 2
                            color: Theme.accent2
                            scale: 0
                            Component.onCompleted: pop.start()
                            NumberAnimation on scale { id: pop; running: false; to: 1; duration: Theme.ms(260); easing.type: Easing.OutBack; easing.overshoot: 2.2 }
                            SequentialAnimation on opacity {
                                running: LockShared.checking
                                loops: Animation.Infinite
                                PauseAnimation { duration: dot.index * 60 }
                                NumberAnimation { to: 0.25; duration: 300; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1; duration: 300; easing.type: Easing.InOutSine }
                                onRunningChanged: if (!running) dot.opacity = 1
                            }
                        }
                    }
                }
            }
        }

        Reveal {
            anchors.horizontalCenter: parent.horizontalCenter
            delay: 0.2
            on: face.main && LockShared.capsLock
            u: face.u

            Item {
                width: capsText.implicitWidth
                height: capsText.implicitHeight + 16 * face.u
                LabelShared {
                    id: capsText
                    y: 16 * face.u
                    text: "\u{f0a5b}  Caps Lock"
                    font.pixelSize: 13 * face.u
                    color: Theme.warn
                }
            }
        }
    }

    Reveal {
        anchors.centerIn: parent
        delay: 0.1
        on: !face.main && LockShared.cfg.music && !!LockShared.player && face.awake
        u: face.u

        Column {
            spacing: 26 * face.u
            Art {
                id: bigArt
                width: Math.round(Math.min(face.width, face.height) * 0.42)
                height: width
                u: face.u
                res: 768
            }
            SwapTextShared {
                width: bigArt.width
                horizontalAlignment: Text.AlignHCenter
                value: LockShared.track.title || ""
                elide: Text.ElideRight
                font.pixelSize: 26 * face.u
                font.capitalization: Theme.caps
                font.letterSpacing: Theme.tracking * face.u
                color: LockShared.ink
            }
        }
    }

    Reveal {
        x: face.portrait ? (face.width - width) / 2 : face.width - width - face.margin
        y: face.height - height - face.margin
        delay: 0.24
        on: face.main && LockShared.cfg.music && !!LockShared.player && face.awake
        u: face.u

        Item {
            id: card
            readonly property var p: LockShared.player
            width: 400 * face.u
            height: 156 * face.u

            Card { anchors.fill: parent; u: face.u }

            Art {
                id: art
                x: 18 * face.u
                anchors.verticalCenter: parent.verticalCenter
                width: 120 * face.u
                height: width
                u: face.u
            }

            Column {
                id: info
                anchors.left: art.right
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 18 * face.u
                anchors.rightMargin: 18 * face.u
                spacing: 3 * face.u

                Row {
                    height: 16 * face.u
                    spacing: 8 * face.u
                    LabelShared {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Now Playing"
                        font.pixelSize: 12 * face.u
                        font.capitalization: Theme.caps
                        font.letterSpacing: Theme.tracking * face.u
                        color: Theme.alpha(LockShared.ink, 0.5)
                    }
                    Wave {
                        anchors.verticalCenter: parent.verticalCenter
                        u: face.u
                        playing: face.main && face.awake && LockShared.cfg.music && !!card.p && card.p.isPlaying && LockShared.t > 0 && !LockShared.leaving
                    }
                }
                SwapTextShared {
                    width: parent.width
                    value: card.p ? LockShared.track.title || "Unknown" : ""
                    elide: Text.ElideRight
                    font.pixelSize: 17 * face.u
                    font.capitalization: Theme.caps
                    font.letterSpacing: Theme.tracking * face.u
                    color: LockShared.ink
                }
                SwapTextShared {
                    width: parent.width
                    value: LockShared.track.artist
                    elide: Text.ElideRight
                    font.pixelSize: 13 * face.u
                    font.capitalization: Theme.caps
                    font.letterSpacing: Theme.tracking * face.u
                    color: Theme.alpha(LockShared.ink, 0.6)
                }

                Item { width: 1; height: 6 * face.u }

                SeekShared {
                    width: parent.width
                    player: card.p
                    u: face.u * 0.8
                    active: face.main && face.awake && LockShared.t > 0 && !LockShared.leaving
                }

                Item { width: 1; height: 4 * face.u }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8 * face.u
                    SkipButtonShared { anchors.verticalCenter: parent.verticalCenter; player: card.p; dir: -1; size: 34 * face.u; tint: LockShared.ink }
                    PlayButtonShared { anchors.verticalCenter: parent.verticalCenter; player: card.p; size: 34 * face.u }
                    SkipButtonShared { anchors.verticalCenter: parent.verticalCenter; player: card.p; dir: 1; size: 34 * face.u; tint: LockShared.ink }
                }
            }
        }
    }

    Reveal {
        x: face.width - width - face.margin
        y: face.margin
        delay: 0.28
        on: face.main && face.awake && ((LockShared.cfg.battery && PowerShared.hasBattery) || LockShared.cfg.power)
        u: face.u

        Row {
            spacing: 8 * face.u

            Item {
                visible: LockShared.cfg.battery && PowerShared.hasBattery
                width: batText.implicitWidth + 30 * face.u
                height: 40 * face.u
                Card { anchors.fill: parent; radius: LockShared.corner(parent.height, face.u) }
                LabelShared {
                    id: batText
                    anchors.centerIn: parent
                    readonly property bool low: !LockShared.charging && PowerShared.charge < 0.2
                    text: (LockShared.charging ? "\u{f0084}" : ["\u{f007b}", "\u{f007c}", "\u{f007e}", "\u{f0080}", "\u{f0082}", "\u{f0079}"][Math.min(5, Math.floor(PowerShared.charge * 6))])
                        + "  " + Math.round(PowerShared.charge * 100) + "%"
                    font.pixelSize: 13 * face.u
                    color: low ? Theme.warn : LockShared.ink
                }
            }

            Repeater {
                model: LockShared.cfg.power ? [
                    { glyph: "\u{f04b2}", id: "suspend" },
                    { glyph: "\u{f0709}", id: "reboot" },
                    { glyph: "\u{f0425}", id: "poweroff" }
                ] : []
                RoundButton {
                    id: pb
                    required property var modelData
                    property bool armedNow: false
                    u: face.u
                    size: 40 * face.u
                    glyph: modelData.glyph
                    armed: armedNow
                    Timer { id: disarm; interval: 3000; onTriggered: pb.armedNow = false }
                    onClicked: {
                        if (PowerShared.confirm(modelData.id) && !armedNow) { armedNow = true; disarm.restart(); return }
                        armedNow = false
                        if (!LockShared.preview) PowerShared.act(modelData.id)
                    }
                }
            }
        }
    }

    Reveal {
        id: gearReveal
        x: face.margin
        y: face.height - height - face.margin
        delay: 0.3
        on: face.main && (face.awake || LockShared.menuOpen)
        u: face.u

        RoundButton {
            u: face.u
            size: 40 * face.u
            glyph: ""
            rotation: LockShared.menuOpen ? 90 : 0
            Behavior on rotation { SettleShared { duration: Theme.ms(420) } }
            onClicked: LockShared.menuOpen = !LockShared.menuOpen
        }
    }

    Item {
        id: menu
        property real p: LockShared.menuOpen && face.main && !LockShared.leaving ? 1 : 0
        Behavior on p { SettleShared { duration: Theme.ms(320) } }

        x: face.margin
        y: gearReveal.y - height - 10 * face.u
        width: 250 * face.u
        height: menuCol.implicitHeight + 24 * face.u
        opacity: p
        visible: p > 0.001
        scale: 0.94 + 0.06 * p
        transformOrigin: Item.BottomLeft
        transform: Translate { y: (1 - menu.p) * 10 * face.u }

        Card { anchors.fill: parent; u: face.u }
        MouseArea { anchors.fill: parent; hoverEnabled: true }

        Column {
            id: menuCol
            x: 12 * face.u
            y: 12 * face.u
            width: parent.width - 24 * face.u
            spacing: 2 * face.u

            LabelShared {
                leftPadding: 8 * face.u
                bottomPadding: 6 * face.u
                text: "Lock screen"
                font.pixelSize: 13 * face.u
                color: Theme.alpha(LockShared.ink, 0.5)
            }
            Repeater {
                model: LockShared.labels
                LockToggleShared {
                    required property var modelData
                    u: face.u
                    label: modelData[1]
                    checked: !!LockShared.cfg[modelData[0]]
                    onToggled: LockShared.set(modelData[0], !checked)
                }
            }
        }
    }

    LabelShared {
        visible: LockShared.preview
        anchors.horizontalCenter: parent.horizontalCenter
        y: 12 * face.u
        text: "Preview · Esc closes"
        font.pixelSize: 12 * face.u
        color: Theme.alpha(LockShared.ink, 0.5)
    }
}
