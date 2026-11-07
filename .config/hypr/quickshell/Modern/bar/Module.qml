import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.SystemTray
import "../../shared"
import "../common"

Item {
    id: mod

    property string name
    property var pill
    property var ctx
    property int slot: 0
    readonly property bool present: !!loader.item && loader.item.visible !== false && (loader.item.on ?? true)

    readonly property string page: pill.opens[name] ?? ""

    implicitWidth: loader.item ? loader.item.implicitWidth : 0
    implicitHeight: pill.pillH
    width: implicitWidth
    height: implicitHeight

    HoverHandler {
        enabled: mod.page === "workspaces" || mod.page === "island" || mod.page === "calendar"
        onHoveredChanged: hovered ? mod.pill.rest(mod.page, null, mod) : mod.pill.unrest(mod)
    }

    MouseArea {
        anchors.fill: parent
        enabled: mod.page === "island"
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => {
            const p = mod.ctx.player
            if (m.button === Qt.LeftButton) mod.pill.toggle("island")
            else MediaShared.toggle(p)
        }
    }

    Loader {
        id: loader
        anchors.verticalCenter: parent.verticalCenter
        sourceComponent: ({ user: userC, workspaces: workspacesC, media: mediaC, date: dateC, constdate: constdateC, timer: timerC, clock: clockC,
            tray: trayC, updates: updatesC, notifications: notificationsC, network: networkC, audio: audioC, power: powerC,
            "|": dividerC })[mod.name] ?? null
    }

    component ChipText: Text {
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        font.family: Theme.sans
        font.pixelSize: 12
        color: Theme.fg
    }

    Component {
        id: userC
        Chip {
            pill: mod.pill
            text: Quickshell.env("USER")
            tint: Theme.accent2
            onClicked: b => mod.ctx.run(HyprShared.util + "/session/shells.sh " + (b === Qt.RightButton ? "settings" : b === Qt.MiddleButton ? "launcher" : "home"))
        }
    }

    Component {
        id: workspacesC
        Item {
            implicitWidth: dots.implicitWidth + 20
            implicitHeight: mod.pill.pillH
            Workspaces.Dots {
                id: dots
                anchors.centerIn: parent
            }
        }
    }

    Component {
        id: mediaC
        Fold {
            on: mod.ctx.showMedia(mod.pill)

            Item {
                implicitWidth: media.implicitWidth + 20
                implicitHeight: mod.pill.pillH

                Row {
                    id: media
                    x: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    SwapTextShared {
                        id: title
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: 12
                        color: Theme.fg
                        property real fit: 170
                        function refit() { if (mod && mod.pill) fit = Math.max(40, Math.min(170, mod.pill.maxW - (mod.pill.rowW - width))) }
                        Connections {
                            target: mod.pill
                            function onRowWChanged() { Qt.callLater(title.refit) }
                            function onMaxWChanged() { Qt.callLater(title.refit) }
                        }
                        width: Math.ceil(Math.min(fullWidth, fit))
                        Behavior on width { SettleShared { duration: Theme.move } }
                        value: [mod.ctx.track.title, mod.ctx.track.artist].filter(s => !!s).join("  ·  ")
                        elide: Text.ElideRight
                    }

                    MiniWaveShared {
                        anchors.verticalCenter: parent.verticalCenter
                        playing: mod.ctx.playing
                        tint: t => Theme.along(Theme.spectrum, t)
                    }
                }
            }
        }
    }

    Component {
        id: dateC
        Fold {
            on: !mod.ctx.showMedia(mod.pill)
            Item {
                implicitWidth: dateText.implicitWidth + 20
                implicitHeight: mod.pill.pillH
                ChipText {
                    id: dateText
                    x: 10
                    text: Qt.formatDate(mod.ctx.now, "ddd, MMM d")
                }
            }
        }
    }

    Component {
        id: constdateC
        Fold {
            Item {
                implicitWidth: dateText.implicitWidth + 20
                implicitHeight: mod.pill.pillH
                ChipText {
                    id: dateText
                    x: 10
                    text: Qt.formatDate(mod.ctx.now, "ddd, MMM d")
                }
            }
        }
    }

    Component {
        id: timerC
        Fold {
            on: mod.ctx.timer.active
            Item {
                implicitWidth: timerBox.width + 8
                implicitHeight: mod.pill.pillH
                Rectangle {
                    id: timerBox
                    x: 4
                    anchors.verticalCenter: parent.verticalCenter
                    height: mod.pill.pillH - 10
                    width: timerText.implicitWidth + 14
                    radius: Math.min(Theme.rounding, height / 2)
                    color: Theme.alpha(Theme.accent, mod.ctx.timer.running ? 0.3 : 0.14)
                    LabelShared {
                        id: timerText
                        anchors.centerIn: parent
                        text: "󰔛 " + mod.ctx.timer.format(mod.ctx.timer.remaining)
                        font.pixelSize: 11
                        color: Theme.bright
                    }
                }
            }
        }
    }

    Component {
        id: clockC
        Item {
            implicitWidth: clockText.implicitWidth + 20
            implicitHeight: mod.pill.pillH
            LabelShared {
                id: clockText
                anchors.centerIn: parent
                text: Theme.clock(mod.ctx.now, false, "AP")
                font.pixelSize: 13
                font.bold: true
                color: Theme.bright
            }
        }
    }

    Component {
        id: trayC
        Fold {
            on: SystemTray.items.values.length > 0

            Repeater {
                model: SystemTray.items

                Chip {
                    required property SystemTrayItem modelData
                    pill: mod.pill
                    page: modelData.hasMenu ? "tray" : ""
                    tray: modelData
                    icon: modelData.icon
                    clickOpens: false
                    onClicked: b => {
                        const item = modelData
                        if (b === Qt.MiddleButton) item.secondaryActivate()
                        else if (b === Qt.RightButton || item.onlyMenu) { if (item.hasMenu) mod.pill.toggle("tray", item) }
                        else if (MediaShared.isSpotify(item)) { mod.pill.close(); MediaShared.openSpotify() }
                        else { mod.pill.close(); item.activate() }
                    }
                    onWheel: dir => modelData.scroll(dir * 120, false)
                }
            }
        }
    }

    Component {
        id: updatesC
        Fold {
            on: mod.ctx.updates > 0
            Chip {
                pill: mod.pill
                page: "updates"
                glyph: "󰅢"
                tint: Theme.caution
                glyphColor: Theme.caution
                text: mod.ctx.updates > 0 ? mod.ctx.updates : ""
            }
        }
    }

    Component {
        id: notificationsC
        Chip {
            pill: mod.pill
            page: "notifications"
            glyph: NotifsShared.dnd ? "󰂛" : "󰂚"
            text: NotifsShared.count || ""
        }
    }

    Component {
        id: networkC
        Row {
            id: netRow
            readonly property var dev: Networking.devices.values.find(d => d.connected && d.type === DeviceType.Wired)
                ?? Networking.devices.values.find(d => d.connected && d.type === DeviceType.Wifi) ?? null
            readonly property var net: dev && dev.type === DeviceType.Wifi ? (dev.networks.values.find(n => n.connected) ?? null) : null
            readonly property var adapter: Bluetooth.defaultAdapter
            readonly property var paired: adapter && adapter.enabled ? adapter.devices.values.filter(d => d.connected) : []

            Chip {
                pill: mod.pill
                page: "network"
                tint: Theme.info
                faded: !netRow.dev
                glyph: {
                    const d = netRow.dev
                    if (!d) return Networking.wifiEnabled ? "󰤯" : "󰤮"
                    if (d.type === DeviceType.Wired) return ""
                    const s = netRow.net ? netRow.net.signalStrength : 1
                    const f = s > 1 ? s / 100 : s
                    return f > 0.75 ? "󰤨" : f > 0.5 ? "󰤥" : f > 0.25 ? "󰤢" : "󰤟"
                }
                text: netRow.net ? netRow.net.name : ""
                maxText: 100
                onClicked: b => { if (b === Qt.RightButton) mod.ctx.run("kitty nmtui") }
            }

            Fold {
                on: netRow.paired.length > 0
                Chip {
                    pill: mod.pill
                    page: "network"
                    glyph: "󰂱"
                    glyphColor: Theme.accent
                    text: netRow.paired.length > 1 ? netRow.paired.length + " devices"
                        : netRow.paired.length === 1 ? (netRow.paired[0].name || "") : ""
                    maxText: 100
                    onClicked: b => { if (b === Qt.RightButton) mod.ctx.run("blueman-manager") }
                }
            }
        }
    }

    Component {
        id: audioC
        Chip {
            id: vol
            readonly property real volume: AudioShared.volume
            readonly property real level: Math.min(1, volume)
            readonly property bool muted: AudioShared.muted

            pill: mod.pill
            page: "audio"
            visible: !!AudioShared.sink
            glyph: muted ? "󰝟" : volume > 0.66 ? "󰕾" : volume > 0.33 ? "󰖀" : "󰕿"
            glyphColor: muted ? Theme.dim : lit ? Theme.accent : Theme.along(Theme.spectrum, level)
            scrub: track
            onScrubbed: f => AudioShared.setVolume(f)
            onClicked: b => {
                if (b === Qt.MiddleButton) AudioShared.toggleMute()
                else if (b === Qt.RightButton) mod.ctx.run("pavucontrol")
            }
            onWheel: dir => AudioShared.nudge(dir)

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 46
                height: 14

                Rectangle {
                    id: track
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: vol.hot ? 6 : 4
                    radius: height / 2
                    color: Theme.alpha(Theme.fg, 0.16)
                    Behavior on height { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }

                    ClippingRectangle {
                        width: Math.max(parent.height, parent.width * vol.level)
                        height: parent.height
                        radius: parent.radius
                        color: "transparent"
                        opacity: vol.muted ? 0.35 : 1
                        Behavior on width { NumberAnimation { duration: vol.scrubbing ? 0 : Theme.fast; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: Theme.fast } }

                        Rectangle {
                            width: track.width
                            height: parent.height
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: Theme.spectrum[0] }
                                GradientStop { position: 0.5; color: Theme.spectrum[Math.floor(Theme.spectrum.length / 2)] }
                                GradientStop { position: 1; color: Theme.spectrum[Theme.spectrum.length - 1] }
                            }
                        }
                    }
                }

                Rectangle {
                    x: Math.max(0, Math.min(parent.width - width, parent.width * vol.level - width / 2))
                    anchors.verticalCenter: parent.verticalCenter
                    width: 10
                    height: 10
                    radius: 5
                    color: Theme.bright
                    scale: vol.hot ? 1 : 0
                    Behavior on scale { NumberAnimation { duration: Theme.ms(160); easing.type: Easing.OutBack } }
                }
            }
        }
    }

    Component {
        id: powerC
        Chip {
            readonly property bool low: PowerShared.discharging && PowerShared.charge < 0.15
            pill: mod.pill
            page: "power"
            glyph: ""
            tint: Theme.ok
            glyphColor: low ? Theme.warn : lit ? tint : PowerShared.charging ? Theme.ok : Theme.bright
        }
    }

    Component {
        id: dividerC
        Fold {
            on: mod.pill.dividerOn(mod.slot)
            Item {
                implicitWidth: 9
                implicitHeight: mod.pill.pillH
                Rectangle {
                    anchors.centerIn: parent
                    width: 1
                    height: 14
                    color: Theme.alpha(Theme.fg, 0.12)
                }
            }
        }
    }

    component Chip: Item {
        id: chip

        property var pill
        property string page: ""
        property var tray: null
        property string glyph: ""
        property string icon: ""
        property string text: ""
        property real maxText: 120
        property string widest: ""
        property bool faded: false
        property bool clickOpens: true
        readonly property bool lit: page !== "" && pill.open && pill.shownPage === page && (page !== "tray" || pill.shownTray === tray)
        property color tint: Theme.accent
        property color glyphColor: lit ? tint : Theme.bright
        property Item scrub: null
        property bool scrubbing: false
        readonly property bool hot: area.containsMouse || scrubbing
        default property alias extra: row.data
        signal clicked(int button)
        signal wheel(int dir)
        signal scrubbed(real f)

        implicitWidth: bg.width + 2
        implicitHeight: pill.pillH
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined

        Rectangle {
            id: bg
            anchors.centerIn: parent
            height: chip.pill.pillH - 2
            width: Math.max(height, row.implicitWidth + 14)
            radius: chip.pill.radius(height)
            color: chip.lit ? Theme.alpha(chip.tint, 0.26) : Theme.alpha(Theme.fg, area.containsMouse ? 0.1 : 0)
            Behavior on color { ColorAnimation { duration: Theme.fast } }

            Row {
                id: row
                anchors.centerIn: parent
                spacing: 5
                opacity: chip.faded ? 0.5 : 1

                IconImage {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: chip.icon !== ""
                    implicitSize: 15
                    source: chip.icon
                }
                LabelShared {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: chip.glyph !== ""
                    width: Math.max(implicitWidth, 15)
                    horizontalAlignment: Text.AlignRight
                    text: chip.glyph
                    font.pixelSize: 14
                    color: chip.glyphColor
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                }
                LabelShared {
                    id: label
                    anchors.verticalCenter: parent.verticalCenter
                    visible: chip.text !== ""
                    width: Math.min(Math.max(implicitWidth, widestText.width), chip.maxText)
                    TextMetrics { id: widestText; font: label.font; text: chip.widest }
                    text: chip.text
                    elide: Text.ElideRight
                    font.pixelSize: 12
                    color: chip.lit || area.containsMouse ? Theme.bright : Theme.fg
                }
            }
        }

        HoverShared {
            id: area
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onContainsMouseChanged: {
                if (chip.page === "") return
                if (containsMouse) chip.pill.rest(chip.page, chip.tray, chip)
                else chip.pill.unrest(chip)
            }
            function scrubTo(m) {
                const p = mapToItem(chip.scrub, m.x, m.y)
                chip.scrubbed(Math.max(0, Math.min(1, p.x / chip.scrub.width)))
            }
            onPressed: m => {
                if (m.button !== Qt.LeftButton || !chip.scrub) return
                const p = mapToItem(chip.scrub, m.x, m.y)
                if (p.x < -4 || p.x > chip.scrub.width + 4) return
                chip.scrubbing = true
                scrubTo(m)
            }
            onPositionChanged: m => { if (chip.scrubbing) scrubTo(m) }
            onReleased: Qt.callLater(() => chip.scrubbing = false)
            onClicked: m => {
                if (chip.scrubbing) return
                if (m.button === Qt.LeftButton && chip.clickOpens && chip.page !== "") chip.pill.toggle(chip.page, chip.tray)
                chip.clicked(m.button)
            }
            onWheel: w => chip.wheel(w.angleDelta.y > 0 ? 1 : -1)
        }
    }

    component Fold: Item {
        id: fold

        property bool on: true
        default property alias content: inner.data

        property real f: on ? 1 : 0
        Behavior on f { NumberAnimation { duration: Theme.move; easing.type: Easing.BezierSpline; easing.bezierCurve: fold.on ? Theme.settle : Theme.leave } }
        property real full: 0
        readonly property real live: inner.implicitWidth
        onLiveChanged: if (on && live > 0) full = live
        onOnChanged: if (on) full = live

        implicitWidth: (on ? live : full) * f
        implicitHeight: inner.implicitHeight
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        clip: true
        opacity: f
        visible: f > 0

        Row {
            id: inner
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
