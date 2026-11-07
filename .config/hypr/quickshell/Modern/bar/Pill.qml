import QtQuick
import QtQuick.Shapes
import "../../shared"
import "../common"
import "menus" as Menus

Item {
    id: self

    property var ctx
    property var screen
    property var modules: []
    property string align: "center"
    property real maxW: 10000
    property bool hurry: false

    readonly property real pillH: ctx.pillH
    readonly property bool filled: ctx.look.background && !ctx.look.strip
    function radius(h) {
        const shape = ctx.look.shape
        return shape === "capsule" ? h / 2 : shape === "square" ? 0 : Math.min(Theme.rounding, h / 2)
    }

    readonly property var opens: ({ workspaces: "workspaces", media: "island", date: "island", constdate: "island", timer: "island",
        clock: "calendar", tray: "tray", updates: "updates", notifications: "notifications", network: "network", audio: "audio", power: "power" })
    function has(page) {
        return modules.some(m => opens[m] === (page === "alarm" ? "island" : page))
    }

    function dividerOn(i) {
        const showing = j => { const m = moduleList.count > j ? moduleList.itemAt(j) : null; return !!m && m.name !== "|" && m.present }
        let before = false, after = false
        for (let j = i - 1; j >= 0 && modules[j] !== "|"; j--) before = before || showing(j)
        for (let j = i + 1; j < modules.length && modules[j] !== "|"; j++) after = after || showing(j)
        return before && after
    }
    readonly property bool wideNet: align === "center"
    readonly property var widths: ({ workspaces: 600, island: 600, network: wideNet ? 672 : 350, calendar: 652, audio: 340, power: 330, tray: 290, updates: 290, notifications: 340, alarm: 300 })
    readonly property var widest: ({ workspaces: 900, island: 900, network: wideNet ? 640 : 560, calendar: 620, audio: 720, power: 420, tray: 360, updates: 360, notifications: 420, alarm: 340 })
    readonly property int pad: 16

    property string page: ""
    property var tray: null
    readonly property bool open: page !== ""
    readonly property string shownPage: front.page
    readonly property var shownTray: front.tray
    property string tab: ""

    function show(p, t) {
        closeDelay.stop()
        openDelay.stop()
        if (p === "") { close(); return }
        const card = MediaShared.card && p === "island"
        const music = ctx.musicInTheWay(self, p)
        if (!open && self.t === 0 && (music || card)) {
            pending = p
            pendingTray = t ?? null
            if (music) { tucked = true; ctx.musicCall("tuck") }
            if (card) MediaShared.dropCard()
            tuckWait.restart()
            return
        }
        place(p, t ?? null)
    }

    readonly property bool onRow: hover.hovered && hover.point.position.y < pillH
    function place(p, t) {
        page = p
        tray = t
        if (front.page === p && front.tray === t) return
        if (self.t > 0) {
            back.page = p
            back.tray = t
            frontIsA = !frontIsA
        } else {
            front.page = p
            front.tray = t
        }
    }

    function close() {
        openDelay.stop()
        closeDelay.stop()
        tuckWait.stop()
        page = ""
    }

    function toggle(p, t) {
        if (open && page === p && (p !== "tray" || tray === t)) close()
        else show(p, t)
    }

    property string pending: ""
    property var pendingTray: null
    property var pendingFrom: null
    function rest(p, t, from) {
        closeDelay.stop()
        pendingFrom = from ?? null
        if (open) show(p, t)
        else { pending = p; pendingTray = t ?? null; openDelay.restart() }
    }
    function unrest(from) {
        if (pendingFrom === (from ?? null)) openDelay.stop()
    }

    readonly property bool hovered: hover.hovered
    readonly property bool holdOpen: open && !!front.item && !!front.item.holdOpen

    onHoveredChanged: {
        if (hovered) closeDelay.stop()
        else { openDelay.stop(); if (open && !holdOpen) closeDelay.restart() }
    }
    onHoldOpenChanged: if (!holdOpen && !hovered && open) closeDelay.restart()

    Timer { id: openDelay; interval: 140; onTriggered: self.show(self.pending, self.pendingTray) }
    Timer { id: closeDelay; interval: 90; onTriggered: if (!self.holdOpen) self.page = "" }

    property bool tucked: false
    property bool musicWasOpen: false
    property bool musicWasTucked: false
    Connections {
        target: self.ctx
        function onMusicChanged() {
            const m = self.ctx.music
            const opened = !!m.open && !self.musicWasOpen
            const cameBack = !!m.open && !m.tucked && self.musicWasTucked && self.tucked
            self.musicWasOpen = !!m.open
            self.musicWasTucked = !!m.tucked
            if (!m.open) self.tucked = false
            if ((opened || cameBack) && self.open && self.screen && m.screen === self.screen.name) { self.tucked = false; self.close() }
        }
    }
    Timer { id: tuckWait; interval: Theme.ms(340); onTriggered: self.place(self.pending, self.pendingTray) }

    readonly property real rawW: row.implicitWidth + 8
    property real slack: 0
    Behavior on slack { SettleShared { duration: Theme.fast } }
    onRawWChanged: settleWait.restart()
    Timer { id: settleWait; interval: Theme.move + 80; onTriggered: self.slack = 2 * Math.ceil(self.rawW / 2) - self.rawW }
    Component.onCompleted: settleWait.restart()
    readonly property real rowW: rawW + slack
    readonly property real targetW: Math.max(rowW, Math.min(maxW, widths[shownPage] ?? 340))
    property real bodyW: targetW
    readonly property bool ownHeight: !!front.item && !!front.item.ownHeight
    property real bodyH: front.item ? (ownHeight ? front.item.implicitHeight : Math.ceil(front.item.implicitHeight)) + 6 + pad : 0
    Behavior on bodyW { enabled: self.t === 1; SettleShared { duration: Theme.move } }
    Behavior on bodyH { enabled: self.t === 1 && !self.ownHeight; SettleShared { duration: Theme.move } }

    property real t: open ? 1 : 0
    Behavior on t {
        NumberAnimation {
            duration: self.hurry && !self.open ? Theme.fast : Theme.move
            easing.type: Easing.BezierSpline
            easing.bezierCurve: self.open ? Theme.settle : Theme.leave
        }
    }
    onTChanged: if (t === 0 && !open) {
        a.page = ""
        a.tray = null
        b.page = ""
        b.tray = null
        tab = ""
        if (tucked) { tucked = false; ctx.musicCall("untuck") }
    }

    y: ctx.attached ? 0 : ctx.edge
    width: rowW
    height: pillH
    visible: modules.length > 0
    z: open ? 2 : t > 0 ? 1 : 0

    readonly property alias card: card

    property bool frontIsA: true
    readonly property Item front: frontIsA ? a : b
    readonly property Item back: frontIsA ? b : a

    Item {
        id: card
        readonly property real grow: (self.bodyW - self.rowW) * self.t
        readonly property real w: self.rowW + grow
        x: self.align === "left" ? 0 : self.align === "right" ? self.rowW - w
            : self.parent ? (self.parent.width - w) / 2 - self.x : (self.rowW - w) / 2
        width: w
        height: self.ownHeight ? self.pillH + self.bodyH * self.t : Math.round(self.pillH + self.bodyH * self.t)

        HoverHandler { id: hover }
        MouseArea { anchors.fill: parent; hoverEnabled: true }

        Item {
            x: -self.ctx.flare
            width: parent.width + 2 * self.ctx.flare
            height: parent.height
            opacity: self.ctx.look.strip ? 0 : Theme.surface(0.6) * (self.filled ? 1 : self.t)
            visible: opacity > 0
            layer.enabled: true
            layer.smooth: true
            layer.mipmap: true
            layer.textureSize: Qt.size(width * 2, height * 2)

            Shape {
                visible: self.ctx.attached
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    id: outline
                    readonly property real f: self.ctx.flare
                    readonly property real r: self.radius(self.pillH)
                    readonly property real w: card.width
                    readonly property real h: card.height - 0.5
                    strokeWidth: 1
                    strokeColor: Qt.tint(Theme.bg, Theme.alpha(Theme.fg, 0.12))
                    fillColor: Theme.bg
                    startX: 0; startY: -1
                    PathLine { x: 0; y: 0 }
                    PathArc { x: outline.f + 0.5; y: outline.f; radiusX: outline.f; radiusY: outline.f }
                    PathLine { relativeX: 0; y: outline.h - outline.r }
                    PathArc { x: outline.f + 0.5 + outline.r; y: outline.h; radiusX: outline.r; radiusY: outline.r; direction: PathArc.Counterclockwise }
                    PathLine { x: outline.f + outline.w - 0.5 - outline.r; y: outline.h }
                    PathArc { x: outline.f + outline.w - 0.5; y: outline.h - outline.r; radiusX: outline.r; radiusY: outline.r; direction: PathArc.Counterclockwise }
                    PathLine { relativeX: 0; y: outline.f }
                    PathArc { x: 2 * outline.f + outline.w; y: 0; radiusX: outline.f; radiusY: outline.f }
                    PathLine { relativeX: 0; y: -1 }
                }
            }

            Rectangle {
                visible: !self.ctx.attached
                x: self.ctx.flare
                width: card.width
                height: parent.height
                radius: self.radius(self.pillH)
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.tint(Theme.bg, Theme.alpha(Theme.fg, 0.2)) }
                    GradientStop { position: Math.min(1, self.pillH / parent.height); color: Qt.tint(Theme.bg, Theme.alpha(Theme.fg, 0.1)) }
                    GradientStop { position: 1; color: Qt.tint(Theme.bg, Theme.alpha(Theme.fg, 0.07)) }
                }
            }
            Rectangle {
                visible: !self.ctx.attached
                x: self.ctx.flare + 1
                y: 1
                width: card.width - 2
                height: parent.height - 2
                radius: Math.max(0, self.radius(self.pillH) - 1)
                color: Theme.bg
            }
        }

        Item {
            y: self.pillH
            width: parent.width
            height: parent.height - self.pillH
            clip: true
            visible: self.t > 0

            Slot { id: a; front: self.frontIsA }
            Slot { id: b; front: !self.frontIsA }
        }

        Row {
            id: row
            x: 4 + self.slack / 2 - card.x
            height: self.pillH

            Repeater {
                id: moduleList
                model: self.modules
                Module {
                    required property string modelData
                    required property int index
                    slot: index
                    name: modelData
                    pill: self
                    ctx: self.ctx
                }
            }
        }
    }

    component Slot: Loader {
        id: slot
        property string page: ""
        property var tray: null
        property bool front: false
        property real f: front ? 1 : 0
        Behavior on f { SettleShared { duration: Theme.move } }

        readonly property real cardLeft: self.x + card.x
        x: self.align === "left" ? self.pad : self.align === "right" ? card.width - width - self.pad
            : Math.round(cardLeft + (card.width - width) / 2) - cardLeft
        y: 6
        property real held: 0
        Binding on held {
            when: slot.front
            value: 2 * Math.floor(Math.min(self.widest[slot.page] ?? Infinity,
                Math.max(self.bodyW, Math.min(self.maxW, self.widths[slot.page] ?? 0)) - self.pad * 2) / 2)
            restoreMode: Binding.RestoreNone
        }
        width: held
        opacity: Math.max(0, self.t * 2 - 1) * f
        visible: opacity > 0
        z: front ? 1 : 0
        transform: Translate { y: (1 - slot.f) * 8 }
        Rise { target: slot.item }
        active: page !== ""
        sourceComponent: ({ workspaces: workspacesC, island: islandC, network: networkC, audio: audioC, power: powerC, tray: trayC, updates: updatesC, notifications: notificationsC, alarm: alarmC, calendar: calendarC })[page] ?? null
    }

    Component { id: workspacesC; Workspaces.Page { expose: self.ctx.expose; screen: self.screen; onPicked: self.close(); onOverview: self.ctx.toggleOverview() } }
    Component { id: islandC; Island { ctx: self.ctx; pill: self } }
    Component { id: networkC; NetworkShared { open: self.open; onRun: c => self.ctx.run(c) } }
    Component { id: updatesC; UpdateMenuShared { onDone: self.close() } }
    Component { id: notificationsC; NotificationsShared {} }
    Component { id: audioC; SoundShared { open: self.open; onRun: c => self.ctx.run(c); onDone: self.close() } }
    Component { id: powerC; Menus.Session { open: self.open; standalone: self.ctx.standalone; onRun: c => self.ctx.run(c); onDone: self.close() } }
    Component { id: calendarC; CalendarShared { open: self.open && self.page === "calendar" } }
    Component { id: alarmC; Alarm { open: self.open && self.page === "alarm"; length: self.ctx.timer.words(self.ctx.timer.total); onDone: self.close() } }
    Component { id: trayC; Menus.Tray { open: self.open; item: parent ? parent.tray : null; onRun: c => self.ctx.run(c); onDone: self.close() } }
}
