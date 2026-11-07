import QtQuick
import QtQuick.Effects
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../../shared"
import "../common"

ShellRoot {
    id: root

    property var all: []
    property var items: []
    property var themes: ["all"]
    property string theme: "all"
    property int cur: 0
    property real pos: 0
    property bool shown: false
    property bool leaving: false
    property real t: 0
    property string indexText: ""
    property var targetScreen: null
    property bool locating: false
    property bool holding: false
    property var previewed: null
    readonly property string previewSrc: previewed ? "file://" + previewed.path : ""
    property bool previewReady: true

    readonly property real panelH: 540
    readonly property real fadeH: 320

    readonly property real u: unitFor(win.screen)

    function unitFor(s) {
        if (!s) return 1
        const v = s.height > s.width
            ? Math.min(s.width / 1100, s.height / 1000)
            : Math.min(s.width / 1600, s.height / 900)
        return Math.max(0.5, v)
    }
    onCurrentChanged: { previewed = current; previewTimer.restart() }
    Timer {
        id: previewTimer
        interval: 120
        onTriggered: if (root.shown && !root.leaving && root.current) root.tint(root.current.colors)
    }

    FileView { id: colorTheme; path: HyprShared.state + "/color-theme"; blockLoading: true; printErrors: false }
    FileView { id: activeBar; path: HyprShared.state + "/bar"; blockLoading: true; printErrors: false }
    property bool tinted: false

    function tint(p) {
        if (!["", "pywal"].includes(colorTheme.text().trim()) || (!p && !tinted)) return
        Theme.preview = p
        tinted = !!p
        if (!Theme.saved) return
        const c = p ?? Array.from({ length: 16 }, (_, i) => Theme.saved.colors["color" + i])
        waybar(["foreground " + c[15], "background " + c[0], "cursor " + c[15], ""]
            .concat(c.map((x, i) => "color" + i + " " + x))
            .concat(["accent " + c[Theme.slotOf("accent")]])
            .map(l => l ? "@define-color " + l + ";" : "").join("\n") + "\n")
        terminals(c)
    }

    function terminals(c) {
        const seq = c.map((x, i) => "\x1b]4;" + i + ";" + x + "\x1b\\").join("")
            + "\x1b]10;" + c[15] + "\x1b\\\x1b]11;" + c[0] + "\x1b\\\x1b]12;" + c[15] + "\x1b\\"
        Quickshell.execDetached(["sh", "-c", 'for t in /dev/pts/[0-9]*; do [ -O "$t" ] && printf %s "$0" > "$t" 2>/dev/null & done; wait', seq])
    }

    function waybar(css) {
        if (activeBar.text().trim() === "quickshell") return
        Quickshell.execDetached(["sh", "-c", '[ -z "$0" ] || printf %s "$0" > ~/.cache/wal/colors-waybar.css; s=~/.config/waybar/style.css; dd if="$s" of="$s" conv=notrunc status=none', css])
    }
    readonly property var current: items.length > 0 ? items[Math.max(0, Math.min(cur, items.length - 1))] : null
    readonly property var palette: current ? current.colors : []
    readonly property var ramp: palette.length === 16
        ? palette.slice().sort((a, b) => lum(a) - lum(b))
        : []

    function lum(c) {
        const q = Qt.color(c)
        return 0.2126 * q.r + 0.7152 * q.g + 0.0722 * q.b
    }

    Behavior on pos { id: posBehavior; NumberAnimation { duration: Theme.ms(380); easing.type: Easing.OutCubic } }

    WatchedShared {
        id: curFile
        path: HyprShared.home + "/.cache/wallpaper-picker/current"
    }
    readonly property string applied: curFile.text().trim()

    onAppliedChanged: {
        if (holding) { holding = false; Theme.preview = null; tinted = false; waybar("") }
        if (!shown) rebuild(applied)
    }

    function jump(i) {
        posBehavior.enabled = false
        cur = i
        pos = i
        posBehavior.enabled = true
    }

    function rebuild(path) {
        const list = theme === "all" ? all
            : theme === "favorites" ? all.filter(w => w.fav)
            : all.filter(w => w.theme === theme)
        if (items !== list) items = list
        const i = path ? list.findIndex(w => w.path === path) : -1
        jump(Math.max(0, i))
    }

    function go(i) {
        if (items.length === 0) return
        cur = Math.max(0, Math.min(items.length - 1, i))
        pos = cur
    }

    function setAll(list) {
        all = list
        const seen = {}
        list.forEach(w => { if (w.theme !== "favorites") seen[w.theme] = true })
        themes = ["all"].concat(list.some(w => w.fav) ? ["favorites"] : [], Object.keys(seen).sort())
        if (!themes.includes(theme)) theme = "all"
    }
    readonly property var favs: {
        const s = {}
        all.forEach(w => { if (w.fav) s[w.path] = true })
        return s
    }
    readonly property var chipThemes: themes.includes("favorites") ? themes : [themes[0], "favorites"].concat(themes.slice(1))

    function favorite() {
        if (!current || favProc.running) return
        const path = current.path
        favProc.command = [HyprShared.util + "/wallpaper/wallpaper-fav.sh", path]
        favProc.running = true
        const i = cur
        setAll(all.map(w => w.path === path ? Object.assign({}, w, { fav: !w.fav }) : w))
        rebuild(path)
        if (current && current.path !== path) jump(Math.min(i, items.length - 1))
    }
    Process { id: favProc; onExited: reindex.restart() }

    function nextTheme(step) {
        const i = themes.indexOf(theme)
        theme = themes[(i + step + themes.length) % themes.length]
        rebuild()
    }

    function apply() {
        if (!current || leaving) return
        holding = current.path !== applied
        holdTimer.restart()
        Quickshell.execDetached([HyprShared.util + "/wallpaper/wallpaper-apply.sh", current.path])
        close()
    }

    function show() {
        Theme.refresh()
        watchdog.stop()
        if ((shown && !leaving) || locating) return
        activeBar.reload()
        colorTheme.reload()
        locating = true
        HyprShared.locate(open)
    }

    function open(screen) {
        locating = false
        if (shown && !leaving) return
        leaving = false
        t = 0
        rebuild(applied)
        targetScreen = screen
        previewed = current
        shown = true
        startTimer.restart()
        Qt.callLater(() => stage.forceActiveFocus())
    }

    function toggle() {
        if (shown && !leaving) close()
        else show()
    }

    function finish() {
        watchdog.stop()
        startTimer.stop()
        tween.stop()
        shown = false
        leaving = false
        t = 0
        if (theme !== "all") theme = "all"
        rebuild(applied)
    }

    Timer { id: holdTimer; interval: 8000; onTriggered: { root.holding = false; root.tint(null) } }

    Timer { id: watchdog; interval: Theme.ms(1200) + 100; onTriggered: root.finish() }

    function animateTo(target) {
        tween.stop()
        tween.from = t
        tween.to = target
        tween.duration = Theme.ms(target === 1 ? 900 : 380)
        tween.easing.type = target === 1 ? Easing.OutCubic : Easing.InOutSine
        tween.start()
    }

    function tryStart() {
        if (shown && !leaving && !tween.running && t === 0) animateTo(1)
    }

    function close() {
        if (!shown || leaving) return
        leaving = true
        previewTimer.stop()
        if (!holding) tint(null)
        startTimer.stop()
        watchdog.restart()
        if (t < 0.001) finish()
        else animateTo(0)
    }

    NumberAnimation {
        id: tween
        target: root
        property: "t"
        onFinished: {
            if (root.leaving) root.finish()
            else if (root.t >= 1) indexer.running = true
        }
    }
    Timer { id: startTimer; interval: 30; onTriggered: root.tryStart() }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void { root.toggle() }
        function open(): void { root.show() }
        function close(): void { root.close() }
    }

    Process {
        id: indexer
        running: true
        command: ["flock", "-w", "5", (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/wallpaper-index.lock",
                  "python3", HyprShared.util + "/wallpaper/wallpaper-index.py"]
        onExited: { idx.reload(); if (reindex.again) { reindex.again = false; running = true } }
    }

    readonly property string library: HyprShared.home + "/wallpapers/library"
    Variants {
        model: [""].concat(root.themes.slice(1))
        delegate: FolderListModel {
            required property string modelData
            folder: "file://" + root.library + (modelData ? "/" + modelData : "")
            showDirs: !modelData
            showFiles: !!modelData
            onCountChanged: reindex.restart()
        }
    }
    Timer {
        id: reindex
        property bool again: false
        interval: 400
        onTriggered: { if (indexer.running) again = true; else indexer.running = true }
    }

    FileView {
        id: idx
        path: HyprShared.home + "/.cache/wallpaper-picker/index.json"
        printErrors: false
        onLoaded: {
            const text = idx.text()
            if (text === root.indexText) return
            let parsed
            try {
                parsed = JSON.parse(text)
            } catch (e) {
                parsed = []
            }
            root.indexText = text
            root.setAll(parsed)
            if (parsed.length === 0) {
                root.close()
                return
            }
            root.rebuild(root.shown && root.current ? root.current.path : root.applied)
        }
    }

    component CrossImage: Item {
        id: ci
        property string src: ""
        property var front: imgA
        readonly property var back: front === imgA ? imgB : imgA
        property bool hold: false
        readonly property bool ready: src === "" || [front, back].some(i => i.status === Image.Ready && i.source.toString() === src)
        property int zTop: 0
        readonly property size decode: Qt.size(Math.ceil(width), Math.ceil(height))

        function promote(img) {
            img.z = ++zTop
            img.opacity = 0
            fade.target = img
            fade.restart()
            front = img
        }

        onSrcChanged: {
            if (src === "") { fade.stop(); imgA.source = ""; imgB.source = "" }
            else if (!fade.running) load()
        }
        onHoldChanged: Qt.callLater(tryPromote)
        function load() {
            if (back.source.toString() === src) tryPromote()
            else back.source = src
        }
        function tryPromote() {
            const b = back
            if (!hold && !fade.running && b.status === Image.Ready && b.source.toString() === src) promote(b)
        }

        NumberAnimation {
            id: fade
            property: "opacity"
            from: 0
            to: 1
            duration: Theme.ms(300)
            easing.type: Easing.InOutSine
            onFinished: { ci.back.source = ""; if (ci.src !== "" && ci.front.source.toString() !== ci.src) ci.load() }
        }

        Image {
            id: imgA
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            sourceSize: ci.decode
            asynchronous: true
            cache: false
            onStatusChanged: if (ci.back === imgA) ci.tryPromote()
        }
        Image {
            id: imgB
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            sourceSize: ci.decode
            asynchronous: true
            cache: false
            opacity: 0
            onStatusChanged: if (ci.back === imgB) ci.tryPromote()
        }
    }

    component Tint: ColorAnimation { duration: Theme.ms(300); easing.type: Easing.InOutSine }
    component CenterText: Text {
        anchors.centerIn: parent
        font.family: Theme.sans
        font.pixelSize: Math.round(14 * root.u)
    }

    component Pass: ShaderEffect {
        anchors.fill: parent
        layer.enabled: true
        layer.smooth: true
        layer.textureSize: area.res
        property real start: 1 - win.height / area.height
        property real span: root.fadeH * root.u / area.height
        property real radius: 24
        property real fade: 0
        fragmentShader: Qt.resolvedUrl("blur.frag.qsb")
    }

    component Pill: Item {
        property color fill
        property color edge
        property real radius
        anchors.fill: parent
        anchors.margins: -2
        layer.enabled: true
        layer.smooth: true
        layer.mipmap: true
        layer.textureSize: Qt.size(Math.ceil(width * 2), Math.ceil(height * 2))
        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: parent.radius
            color: parent.fill
            Behavior on color { Tint {} }
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: parent.edge
        }
    }

    component ChipRow: Item {
        id: row
        property Item sel: null
        property bool settled: false
        readonly property int h: Math.round(36 * root.u)
        readonly property int pad: Math.round(36 * root.u)
        readonly property real radius: Math.min(h / 2, Theme.rounding)
        readonly property int lead: Theme.ms(260)
        readonly property int trail: Theme.ms(420)

        readonly property int gap: Math.round(8 * root.u)
        readonly property int grow: Theme.ms(380)

        x: Math.round((parent.width - width) / 2)
        y: Math.round(110 * root.u)
        width: Math.max(0, chips.width - gap)
        height: chips.height
        opacity: Math.max(0.001, Theme.seg(root.t, 0))
        transform: Translate { y: (1 - Theme.seg(root.t, 0)) * 40 * root.u }

        Row {
            id: chips
            Repeater {
                id: chipRep
                model: root.chipThemes
                onItemAdded: { row.settled = false; settleChips.restart() }
                delegate: Item {
                    id: chip
                    required property string modelData
                    readonly property bool active: root.theme === modelData
                    readonly property bool present: modelData !== "favorites" || root.themes.includes(modelData)
                    readonly property real full: Math.round(label.implicitWidth) + row.pad
                    property real shown: present ? 1 : 0
                    Behavior on shown { NumberAnimation { duration: row.grow; easing.type: Easing.OutCubic } }
                    onPresentChanged: { row.settled = false; settleChips.restart() }
                    onActiveChanged: if (active) row.sel = chip
                    Component.onCompleted: if (active) row.sel = chip
                    width: (full + row.gap) * shown
                    height: row.h
                    visible: shown > 0

                    Item {
                        width: chip.full
                        height: row.h
                        opacity: chip.shown
                        scale: 0.6 + 0.4 * chip.shown
                        Pill { radius: row.radius; fill: Theme.panel; edge: Theme.edge }
                        CenterText { id: label; text: chip.modelData; color: "#ffffff" }
                        MouseArea {
                            anchors.fill: parent
                            enabled: chip.present
                            onClicked: { root.theme = chip.modelData; root.rebuild() }
                        }
                    }
                }
            }
        }
        Timer { id: settleChips; interval: row.grow + 20; onTriggered: row.settled = true }

        Item {
            id: highlight
            visible: !!row.sel
            property real l: row.sel ? row.sel.x : 0
            property real r: row.sel ? row.sel.x + row.sel.full : 0
            Behavior on l { id: lb; enabled: row.settled; NumberAnimation { duration: lb.targetValue > highlight.l ? row.trail : row.lead; easing.type: Easing.OutCubic } }
            Behavior on r { id: rb; enabled: row.settled; NumberAnimation { duration: rb.targetValue > highlight.r ? row.lead : row.trail; easing.type: Easing.OutCubic } }
            x: l
            width: r - l
            height: row.h

            Pill { radius: row.radius; fill: Theme.soft(Theme.accent); edge: "transparent" }

            Item {
                anchors.fill: parent
                clip: true
                Item {
                    x: -highlight.x
                    Repeater {
                        model: root.chipThemes
                        Item {
                            required property string modelData
                            required property int index
                            readonly property Item chip: chipRep.count, chipRep.itemAt(index)
                            x: chip ? chip.x : 0
                            width: chip ? chip.full : 0
                            height: row.h
                            opacity: chip ? chip.shown : 0
                            CenterText {
                                id: dark
                                text: parent.modelData
                                color: Theme.ink
                                Behavior on color { Tint {} }
                            }
                        }
                    }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.shown || root.holding
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "wallpaper-picker-preview"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            CrossImage {
                id: shot
                anchors.fill: parent
                src: root.shown || root.holding ? root.previewSrc : ""
                hold: modelData === win.screen && !backdrop.ready
                opacity: root.holding ? 1 : root.t
            }
            Binding { target: root; property: "previewReady"; value: shot.ready; when: modelData === win.screen }
            MouseArea { anchors.fill: parent; onClicked: root.close() }
        }
    }

    PanelWindow {
        id: win
        visible: root.shown
        screen: root.targetScreen ?? Quickshell.screens[0]
        anchors { bottom: true; left: true; right: true }
        implicitHeight: Math.ceil(root.panelH * root.u)
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "wallpaper-picker"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Item {
            id: area
            width: parent.width
            height: win.screen ? win.screen.height : parent.height
            y: parent.height - height
            opacity: Math.max(0.001, root.t)
            readonly property size res: Qt.size(Math.ceil(width / 3), Math.ceil(height / 3))

            CrossImage {
                id: backdrop
                anchors.fill: parent
                src: root.previewed ? "file://" + root.previewed.thumb : ""
                hold: !root.previewReady
                visible: false
                layer.enabled: true
                layer.smooth: true
                layer.textureSize: area.res
            }

            Pass {
                id: across
                visible: false
                property var source: backdrop
                property vector2d texel: Qt.vector2d(1 / area.res.width, 0)
            }
            Pass {
                property var source: across
                property vector2d texel: Qt.vector2d(0, 1 / area.res.height)
                fade: 1
            }

            Rectangle {
                id: haze
                anchors.fill: parent
                readonly property real a: 1 - win.height / height
                readonly property real d: root.fadeH * root.u / height
                gradient: Gradient {
                    GradientStop { position: haze.a; color: Theme.back(0) }
                    GradientStop { position: haze.a + haze.d / 3; color: Theme.back(0.07) }
                    GradientStop { position: haze.a + haze.d * 2 / 3; color: Theme.back(0.25) }
                    GradientStop { position: haze.a + haze.d; color: Theme.back(0.35) }
                    GradientStop { position: 1; color: Theme.back(0.45) }
                }
            }
        }

        Item {
            id: stage
            width: parent.width / root.u
            height: parent.height / root.u
            scale: root.u
            transformOrigin: Item.TopLeft
            focus: true

            Keys.onPressed: event => {
                const k = event.key
                if (k === Qt.Key_Escape) root.close()
                else if (k === Qt.Key_Right || k === Qt.Key_L) root.go(root.cur + 1)
                else if (k === Qt.Key_Left || k === Qt.Key_H) root.go(root.cur - 1)
                else if (k === Qt.Key_Home) root.go(0)
                else if (k === Qt.Key_End) root.go(root.items.length - 1)
                else if (k === Qt.Key_PageDown) root.go(root.cur + 5)
                else if (k === Qt.Key_PageUp) root.go(root.cur - 5)
                else if (k === Qt.Key_Tab || k === Qt.Key_Down || k === Qt.Key_J) root.nextTheme(1)
                else if (k === Qt.Key_Backtab || k === Qt.Key_Up || k === Qt.Key_K) root.nextTheme(-1)
                else if (k === Qt.Key_R) root.go(Math.floor(Math.random() * root.items.length))
                else if (k === Qt.Key_F) root.favorite()
                else if (k === Qt.Key_Return || k === Qt.Key_Enter) root.apply()
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
                onWheel: wheel => root.go(root.cur + (wheel.angleDelta.y + wheel.angleDelta.x < 0 ? 1 : -1))
            }

            Item {
                id: wheel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 180
                height: 250
                opacity: Math.max(0.001, Theme.seg(root.t, 0.08))
                transform: Translate { y: (1 - Theme.seg(root.t, 0.08)) * 60 }

                readonly property real cardW: 400
                readonly property real cardH: 225
                readonly property real step: cardW + 28
                readonly property real reach: width / 2 / step + 1

                Repeater {
                    model: ScriptModel { values: root.items; objectProp: "path" }
                    delegate: Item {
                        id: card
                        required property var modelData
                        required property int index
                        readonly property real d: index - root.pos
                        readonly property real ad: Math.abs(d)

                        visible: ad < wheel.reach
                        width: wheel.cardW
                        height: wheel.cardH
                        y: (wheel.height - height) / 2
                        x: (wheel.width - width) / 2 + d * wheel.step
                        z: 100 - ad * 10
                        scale: 1 - 0.08 * Math.min(ad, 1)

                        transform: Rotation {
                            origin.x: card.width / 2
                            origin.y: card.height / 2
                            axis { x: 0; y: 1; z: 0 }
                            angle: -Math.max(-2.5, Math.min(2.5, card.d)) * 6
                        }

                        Loader {
                            anchors.fill: parent
                            active: card.ad < wheel.reach + 3
                            sourceComponent: frame
                        }

                        Component {
                            id: frame
                            Item {
                                readonly property real k: 2 * root.u * (win.devicePixelRatio || 1)
                                readonly property real radius: Theme.rounding / root.u
                                anchors.fill: parent
                                anchors.margins: -2
                                layer.enabled: true
                                layer.smooth: true
                                layer.mipmap: true
                                layer.textureSize: Qt.size(Math.ceil(width * k), Math.ceil(height * k))

                                ClippingRectangle {
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    radius: parent.radius
                                    color: "#22000000"

                                    Image {
                                        anchors.fill: parent
                                        source: "file://" + card.modelData.thumb
                                        sourceSize.width: 640
                                        sourceSize.height: 360
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: true
                                        opacity: status === Image.Ready ? 1 : 0
                                        Behavior on opacity { NumberAnimation { duration: Theme.ms(300) } }
                                    }
                                    Rectangle {
                                        anchors.fill: parent
                                        gradient: Gradient {
                                            GradientStop { position: 0; color: "#30ffffff" }
                                            GradientStop { position: 0.45; color: "#00ffffff" }
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    radius: parent.radius
                                    color: "transparent"
                                    border.width: 1.5 / root.u
                                    border.color: card.ad < 0.5 ? "#80ffffff" : "#40ffffff"
                                    Behavior on border.color { ColorAnimation { duration: Theme.ms(250) } }
                                }

                                LabelShared {
                                    visible: !!root.favs[card.modelData.path]
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 14
                                    text: ""
                                    font.pixelSize: 18
                                    color: Theme.accent
                                    style: Text.Raised
                                    styleColor: "#60000000"
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: card.index === root.cur ? root.apply() : root.go(card.index)
                        }
                    }
                }
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: wheel.bottom
                anchors.topMargin: 18
                spacing: 14
                opacity: Math.max(0.001, Theme.seg(root.t, 0.22))
                transform: Translate { y: (1 - Theme.seg(root.t, 0.22)) * 40 }

                LabelShared {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.current ? root.current.name.replace(/[_-]/g, " ") : ""
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, 700)
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 18
                    color: "#ffffff"
                }

                ClippingRectangle {
                    id: strip
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 520
                    height: 10
                    radius: Math.min(height / 2, Theme.rounding / root.u)
                    color: "#22ffffff"

                    Row {
                        Repeater {
                            model: 16
                            Rectangle {
                                required property int index
                                width: strip.width / 16
                                height: strip.height
                                color: root.ramp[index] ?? "transparent"
                                Behavior on color { ColorAnimation { duration: Theme.ms(420); easing.type: Easing.InOutSine } }
                            }
                        }
                    }
                }
            }
        }

        ChipRow { id: chipBar }
    }
}
