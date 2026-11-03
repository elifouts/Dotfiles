import QtQuick
import QtQuick.Effects
import Quickshell
import "../common"

Item {
    id: face

    property string screenName
    readonly property bool portrait: height > width
    // same sizing as the home screen
    readonly property real u: portrait
        ? Math.max(0.6, Math.min(width / 760, height / 1350))
        : Math.max(0.6, Math.min(width / 1600, height / 900))

    readonly property bool main: screenName === (Lock.lockedOn || (Quickshell.screens[0] || {}).name)
    readonly property bool awake: !Lock.idle
    readonly property real margin: 32 * u

    // preview has no handoff, so fade itself
    opacity: Lock.preview ? Lock.fade : 1

    Rectangle { anchors.fill: parent; color: "black" }

    Item {
        anchors.fill: parent
        scale: 1 + 0.035 * Lock.t

        Image {
            id: shot
            anchors.fill: parent
            source: face.screenName ? "file://" + Lock.shots + "/" + face.screenName + ".ppm" : ""
            fillMode: Image.PreserveAspectCrop
            cache: false
            // load first so it never flashes black
            asynchronous: false
        }
        // never 0, or Qt skips the first blur render
        MultiEffect {
            anchors.fill: parent
            source: shot
            visible: shot.status === Image.Ready
            opacity: Math.max(0.001, Math.min(1, Lock.t * 2.2))
            blurEnabled: true
            blurMax: 64
            blur: 1
            autoPaddingEnabled: false
        }
    }
    Backdrop {
        anchors.fill: parent
        t: Lock.t
        source: Lock.wallpaper
        opacity: Math.max(0.001, shot.status === Image.Ready ? Math.min(1, (Lock.t - 0.2) * 1.8) : 1)
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: Lock.poke()
        onClicked: { Lock.menuOpen = false; input.forceActiveFocus() }
    }

    // one per monitor so typing works wherever focus is
    TextInput {
        id: input
        width: 0
        height: 0
        opacity: 0
        focus: true
        echoMode: TextInput.Password
        text: Lock.password
        onTextEdited: { Lock.password = text; Lock.failed = false; Lock.poke() }
        onAccepted: Lock.submit()
        Keys.onPressed: event => {
            Lock.poke()
            Lock.checkCaps()
            if (event.key === Qt.Key_Escape) {
                if (Lock.menuOpen) Lock.menuOpen = false
                else if (Lock.preview && Lock.password === "") Lock.leave()
                else Lock.password = ""
                event.accepted = true
            }
        }
        Component.onCompleted: forceActiveFocus()
        Connections {
            target: Lock
            function onMenuOpenChanged() { if (!Lock.menuOpen) input.forceActiveFocus() }
        }
    }

    SystemClock { id: clock; precision: SystemClock.Seconds }

    Reveal {
        x: face.margin
        y: face.margin
        delay: 0.1
        on: face.main && Lock.cfg.greeter && face.awake
        u: face.u
        Label {
            text: "Hello, <b>" + Lock.user + "</b>"
            textFormat: Text.StyledText
            font.pixelSize: 22 * face.u
            color: "#ffffff"
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: (face.main && face.portrait ? -140 : -30) * face.u

        Reveal {
            anchors.horizontalCenter: parent.horizontalCenter
            delay: 0.02
            on: Lock.cfg.clock
            u: face.u

            Column {
                Row {
                    id: clockRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    readonly property real size: 150 * face.u
                    readonly property string hh: String(clock.hours % 12 || 12).padStart(2, "0")
                    readonly property string mm: String(clock.minutes).padStart(2, "0")

                    Digit { value: clockRow.hh[0]; size: clockRow.size }
                    Digit { value: clockRow.hh[1]; size: clockRow.size }
                    Label {
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
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(clock.date, "dddd, d MMMM")
                    font.pixelSize: 24 * face.u
                    color: "#ccffffff"
                }
            }
        }

        Item { width: 1; height: (face.main ? 56 : 0) * face.u }

        Reveal {
            anchors.horizontalCenter: parent.horizontalCenter
            delay: 0.16
            on: face.main && (face.awake || Lock.password !== "")
            u: face.u

            Item {
                id: field
                readonly property real h: 54 * face.u
                readonly property bool typing: Lock.password !== ""
                width: typing ? dots.width + h + 22 * face.u : h
                height: h
                Behavior on width { Settle { duration: Theme.ms(300) } }

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
                    target: Lock
                    function onRejected() { shake.restart() }
                }

                Card {
                    anchors.fill: parent
                    radius: Lock.corner(field.h, face.u)
                }
                Rectangle {
                    anchors.fill: parent
                    radius: Lock.corner(field.h, face.u)
                    color: "transparent"
                    border.width: 1.5 * face.u
                    border.color: Lock.failed ? Theme.warn : Theme.accent
                    opacity: Lock.failed ? 1 : field.typing ? 0.5 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.ms(200) } }
                    Behavior on border.color { ColorAnimation { duration: Theme.ms(200) } }
                }

                Label {
                    x: (field.h - width) / 2
                    anchors.verticalCenter: parent.verticalCenter
                    text: ""
                    font.pixelSize: 19 * face.u
                    color: Lock.failed ? Theme.warn : field.typing ? Theme.accent : "#ffffff"
                    Behavior on color { ColorAnimation { duration: Theme.ms(200) } }
                }

                Row {
                    id: dots
                    x: field.h - 4 * face.u
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8 * face.u
                    Repeater {
                        model: Math.min(Lock.password.length, 24)
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
                                running: Lock.checking
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
            on: face.main && Lock.capsLock
            u: face.u

            Item {
                width: capsText.implicitWidth
                height: capsText.implicitHeight + 16 * face.u
                Label {
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
        x: face.portrait ? (face.width - width) / 2 : face.width - width - face.margin
        y: face.height - height - face.margin
        delay: 0.24
        on: face.main && Lock.cfg.music && !!Lock.player && face.awake
        u: face.u

        Item {
            id: card
            readonly property var p: Lock.player
            width: 400 * face.u
            height: 156 * face.u

            Card { anchors.fill: parent; u: face.u }

            Cover {
                id: art
                x: 18 * face.u
                anchors.verticalCenter: parent.verticalCenter
                width: 120 * face.u
                height: width
                radius: Lock.corner(width, face.u)
                fill: Theme.alpha(Theme.info, 0.12)
                glyph: ""
                glyphColor: Theme.info
                url: Lock.track.art
            }

            Column {
                id: info
                anchors.left: art.right
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 18 * face.u
                anchors.rightMargin: 18 * face.u
                spacing: 3 * face.u

                // fixed height so the text doesn't move
                Row {
                    height: 16 * face.u
                    spacing: 8 * face.u
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Now Playing"
                        font.pixelSize: 12 * face.u
                        color: "#80ffffff"
                    }
                    Wave {
                        anchors.verticalCenter: parent.verticalCenter
                        u: face.u
                        // only while the card is on screen, cava is the one real background job
                        playing: face.main && face.awake && Lock.cfg.music && !!card.p && card.p.isPlaying && Lock.t > 0 && !Lock.leaving
                    }
                }
                SwapText {
                    width: parent.width
                    value: card.p ? Lock.track.title || "Unknown" : ""
                    elide: Text.ElideRight
                    font.pixelSize: 17 * face.u
                    color: "#ffffff"
                }
                SwapText {
                    width: parent.width
                    value: Lock.track.artist
                    elide: Text.ElideRight
                    font.pixelSize: 13 * face.u
                    color: "#99ffffff"
                }

                Item { width: 1; height: 6 * face.u }

                Seek {
                    width: parent.width
                    player: card.p
                    u: face.u * 0.8
                    active: face.main && face.awake && Lock.t > 0 && !Lock.leaving
                }

                Item { width: 1; height: 4 * face.u }

                Row {
                    spacing: 8 * face.u
                    SkipButton { anchors.verticalCenter: parent.verticalCenter; player: card.p; dir: -1; size: 34 * face.u; tint: "#ffffff" }
                    PlayButton { anchors.verticalCenter: parent.verticalCenter; player: card.p; size: 34 * face.u }
                    SkipButton { anchors.verticalCenter: parent.verticalCenter; player: card.p; dir: 1; size: 34 * face.u; tint: "#ffffff" }
                }
            }
        }
    }

    Reveal {
        x: face.width - width - face.margin
        y: face.margin
        delay: 0.28
        on: face.main && face.awake && ((Lock.cfg.battery && Power.hasBattery) || Lock.cfg.power)
        u: face.u

        Row {
            spacing: 8 * face.u

            Item {
                visible: Lock.cfg.battery && Power.hasBattery
                width: batText.implicitWidth + 30 * face.u
                height: 40 * face.u
                Card { anchors.fill: parent; radius: Lock.corner(parent.height, face.u) }
                Label {
                    id: batText
                    anchors.centerIn: parent
                    readonly property bool low: !Lock.charging && Power.charge < 0.2
                    text: (Lock.charging ? "\u{f0084}" : ["\u{f007b}", "\u{f007c}", "\u{f007e}", "\u{f0080}", "\u{f0082}", "\u{f0079}"][Math.min(5, Math.floor(Power.charge * 6))])
                        + "  " + Math.round(Power.charge * 100) + "%"
                    font.pixelSize: 13 * face.u
                    color: low ? Theme.warn : "#ffffff"
                }
            }

            Repeater {
                model: Lock.cfg.power ? [
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
                        if (Power.confirm(modelData.id) && !armedNow) { armedNow = true; disarm.restart(); return }
                        armedNow = false
                        if (!Lock.preview) Power.act(modelData.id)
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
        on: face.main && (face.awake || Lock.menuOpen)
        u: face.u

        RoundButton {
            u: face.u
            size: 40 * face.u
            glyph: ""
            rotation: Lock.menuOpen ? 90 : 0
            Behavior on rotation { Settle { duration: Theme.ms(420) } }
            onClicked: Lock.menuOpen = !Lock.menuOpen
        }
    }

    Item {
        id: menu
        property real p: Lock.menuOpen && face.main && !Lock.leaving ? 1 : 0
        Behavior on p { Settle { duration: Theme.ms(320) } }

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
        // eat clicks so the menu stays open
        MouseArea { anchors.fill: parent; hoverEnabled: true }

        Column {
            id: menuCol
            x: 12 * face.u
            y: 12 * face.u
            width: parent.width - 24 * face.u
            spacing: 2 * face.u

            Label {
                leftPadding: 8 * face.u
                bottomPadding: 6 * face.u
                text: "Lock screen"
                font.pixelSize: 13 * face.u
                color: "#80ffffff"
            }
            Repeater {
                model: Lock.labels
                Toggle {
                    required property var modelData
                    u: face.u
                    label: modelData[1]
                    checked: !!Lock.cfg[modelData[0]]
                    onToggled: Lock.set(modelData[0], !checked)
                }
            }
        }
    }

    Label {
        visible: Lock.preview
        anchors.horizontalCenter: parent.horizontalCenter
        y: 12 * face.u
        text: "Preview · Esc closes"
        font.pixelSize: 12 * face.u
        color: "#80ffffff"
    }
}
