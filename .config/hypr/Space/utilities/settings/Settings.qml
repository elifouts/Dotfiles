import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../common"
import "Motion.js" as Motion
import "../common/Schema.js" as Schema

PanelWindow {
    id: sheet

    signal done()
    screen: Ui.target
    anchors.bottom: true
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: Math.min(1240, (screen?.width ?? 1240) - 32)
    implicitHeight: 560
    color: "transparent"
    mask: Region { item: frame }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "space-settings"
    WlrLayershell.keyboardFocus: Ui.touring ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive

    property string tab: Ui.sheet
    readonly property var tabs: ["core", "colors", "fonts"].concat(Schema.PAGES.map(p => p.id), "profiles")
    readonly property var page: Schema.PAGES.find(p => p.id === tab)
    property int dir: 1
    property int was: tabs.indexOf(tab)
    onTabChanged: {
        const i = tabs.indexOf(tab)
        dir = i >= was ? 1 : -1
        was = i
        swap.restart()
    }
    Component.onCompleted: { Store.refresh(); morph.open() }
    function close() { morph.close() }
    function open() { morph.open() }
    function toggle() { morph.leaving ? morph.open() : morph.close() }
    Morph { id: morph; openMs: 560; closeMs: 340; onClosed: sheet.done() }
    property real w: Math.min(implicitWidth, Math.max(tabRow.implicitWidth + 96, content.implicitWidth + 48))
    property real h: Math.min(implicitHeight, content.implicitHeight + 46)
    Behavior on w { Settle { duration: Theme.fast } }
    Behavior on h { Settle { duration: Theme.fast } }
    function step(d) {
        tab = tabs[(tabs.indexOf(tab) + d + tabs.length) % tabs.length]
    }
    HyprlandFocusGrab { active: !Ui.touring && !morph.leaving; windows: [sheet]; onCleared: sheet.close() }

    component Caption: Hud { width: 150; height: 20; caps: false; elide: Text.ElideRight; color: Theme.dim }
    component Pick: Flow {
        id: pick
        property string label
        property var options: []
        property string key
        property var fallback
        readonly property var raw: Store.values[key]
        property var current: raw === "" ? options.find(o => o.dflt)?.v : raw ?? fallback
        readonly property bool many: options.length > 6
        readonly property var shown: many ? [options.find(o => (o.v ?? o) === current) ?? options[0]] : options
        readonly property bool fits: shown.reduce((n, o) => n + String(o.l ?? o).length * 8.2 + 12, 0) <= width - 158
        signal chose(var v)
        onChose: v => { if (key) Store.set(key, v) }
        function next(d) {
            const i = options.findIndex(o => (o.v ?? o) === current), o = options[(i + d + options.length) % options.length]
            chose(o.v ?? o)
        }
        width: 320
        Caption { width: 158; text: pick.label }
        Flow {
            width: pick.fits ? pick.width - 158 : pick.width
            spacing: 12
            Repeater {
                model: pick.shown
                Hud {
                    required property var modelData
                    readonly property var v: modelData.v ?? modelData
                    text: (modelData.l ?? modelData) + (pick.many ? " \u203a" : "")
                    height: 20
                    color: v === pick.current ? Theme.accent : area.containsMouse ? Theme.fg : Theme.dim
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: pick.many ? pick.next(1) : pick.chose(parent.v)
                        onWheel: w => { if (pick.many) pick.next(w.angleDelta.y < 0 ? 1 : -1) }
                    }
                }
            }
        }
    }
    component Toggle: Item {
        id: tg
        property string label
        property string key
        property bool fallback: true
        property var raises
        readonly property bool on: !!(Store.values[key] ?? fallback)
        width: 320
        implicitHeight: 20
        Caption { width: tg.width - 40; text: tg.label }
        Kit.Toggle {
            anchors.right: parent.right
            height: 20
            on: tg.on
            onFlip: {
                const r = tg.raises, next = { [tg.key]: !tg.on }
                if (!tg.on && r && Store.values[r.key] < r.min) next[r.key] = r.min
                Store.setMany(next)
            }
        }
    }
    component Knob: Row {
        id: knob
        property string key
        property string label
        property string unit
        property real from: 0
        property real to: 1
        property real step: 1
        property real fallback: from
        readonly property real v: Store.values[key] ?? fallback
        readonly property int digits: (String(step).split(".")[1] ?? "").length
        width: 320
        spacing: 8
        Caption { text: knob.label }
        Kit.Slide {
            width: knob.width - 158
            height: 20
            scrollable: false
            readout: knob.v.toFixed(knob.digits) + knob.unit
            value: (knob.v - knob.from) / (knob.to - knob.from)
            onMoved: x => Store.set(knob.key, Number((Math.round((knob.from + x * (knob.to - knob.from)) / knob.step) * knob.step).toFixed(knob.digits)))
        }
    }

    Rectangle {
        id: frame
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -(1 - morph.rise) * 18
        readonly property real fw: 44 + (sheet.w - 44) * Math.min(1, morph.mw)
        x: Math.round((sheet.width - fw) / 2)
        width: Math.round((sheet.width + fw) / 2) - x
        height: Math.round(10 + (sheet.h - 10) * Math.min(1, morph.mh))
        opacity: Math.min(1, morph.t * 6)
        clip: true
        color: Theme.alpha(Theme.bg, 0.8)
        border.width: 1
        border.color: Theme.alpha(Theme.accent, 0.3)
        Rectangle { width: parent.width; height: 2; color: Theme.accent }
        MouseArea {
            anchors.fill: parent
            z: 1
            onPressed: m => { sheetKeys.forceActiveFocus(); m.accepted = false }
        }

        Item {
            x: Math.round((frame.fw - sheet.w) / 2)
            width: Math.round(sheet.w)
            height: Math.round(sheet.h)
            opacity: morph.stage(0.5)

            Row {
                id: tabRow
                x: 24
                y: 10
                spacing: 18
                Repeater {
                    id: tabItems
                    model: sheet.tabs
                    Hud {
                        required property string modelData
                        text: modelData
                        color: sheet.tab === modelData ? Theme.accent : Theme.dim
                        MouseArea { anchors.fill: parent; onClicked: sheet.tab = parent.modelData }
                    }
                }
            }
            Rectangle {
                readonly property Item on: tabItems.count ? tabItems.itemAt(sheet.tabs.indexOf(sheet.tab)) : null
                x: tabRow.x + (on?.x ?? 0)
                y: tabRow.y + tabRow.height + 3
                width: on?.width ?? 0
                height: 1
                color: Theme.accent
                Behavior on x { Settle { duration: Theme.fast } }
                Behavior on width { Settle { duration: Theme.fast } }
            }
            Hud { anchors.right: parent.right; anchors.rightMargin: 24; y: 10; text: "esc"; color: Theme.alpha(Theme.fg, 0.25) }

            Loader {
                id: content
                x: 24
                y: 34
                transform: Translate { id: shift }
                onLoaded: sheetKeys.forceActiveFocus()
                sourceComponent: ({ core: core, colors: colors, fonts: fonts, profiles: profiles })[sheet.tab] ?? pageView
            }
            ParallelAnimation {
                id: swap
                Settle { target: content; property: "opacity"; from: 0; to: 1; duration: Theme.fast }
                Settle { target: shift; property: "x"; from: 24 * sheet.dir; to: 0; duration: Theme.fast }
            }
        }
    }

    Component {
        id: core
        Row {
            spacing: 24
            Column {
                Pick {
                    label: "Style"
                    options: Object.keys(Store.styles).sort()
                    current: Store.active.style
                    onChose: v => {
                        const vs = Store.styles[v] || []
                        if (v !== Store.active.style) Store.applyProfile(v, vs.includes(Store.active.variant) ? Store.active.variant : vs[0])
                    }
                }
                Pick {
                    label: "Machine"
                    options: Store.styles[Store.active.style] || []
                    current: Store.active.variant
                    onChose: v => { if (v !== Store.active.variant) Store.applyProfile(Store.active.style, v) }
                }
            }
            Column {
                Toggle { label: "24h clock"; key: "space.clock24" }
                Knob { label: "Pan distance"; key: "space.parallax"; from: 0.2; to: 2; step: 0.1; fallback: 1 }
            }
        }
    }

    Component {
        id: pageView
        Row {
            spacing: 24
            Repeater {
                model: sheet.page?.columns ?? []
                Column {
                    id: col
                    required property var modelData
                    required property int index
                    readonly property var all: modelData.reduce((a, s) => a.concat(s.controls), [])
                    width: all.some(c => c.type === "bezier") ? 560 : 320
                    visible: all.some(c => Schema.shown(c, Store.values, Store.caps))
                    spacing: 10
                    Repeater {
                        model: col.modelData
                        Column {
                            id: sec
                            required property var modelData
                            required property int index
                            visible: modelData.controls.some(c => Schema.shown(c, Store.values, Store.caps))
                            width: col.width
                            spacing: 2
                            Kit.Title { glyph: "\u25c6"; text: sec.modelData.label }
                            Repeater {
                                model: sec.modelData.controls
                                Loader {
                                    id: ctl
                                    required property var modelData
                                    readonly property var def: modelData
                                    width: sec.width
                                    height: item?.implicitHeight ?? 0
                                    visible: Schema.shown(def, Store.values, Store.caps)
                                    active: visible
                                    sourceComponent: ({ slider: slider, toggle: flip, choice: choice, bezier: bezier, animpreset: preset, cursors: cursors })[def.type]
                                    Component { id: slider; Knob { key: ctl.def.key; label: ctl.def.label; unit: ctl.def.unit; from: ctl.def.min; to: ctl.def.max; step: ctl.def.step } }
                                    Component { id: flip; Toggle { key: ctl.def.key; label: ctl.def.label; raises: ctl.def.raises } }
                                    Component { id: choice; Pick { key: ctl.def.key; label: ctl.def.label; options: ctl.def.options } }
                                    Component { id: bezier; SettingBezier {} }
                                    Component {
                                        id: preset
                                        Pick {
                                            label: "Preset"
                                            options: Motion.PRESET_OPTIONS
                                            current: Store.values["animation.preset"] || "theme"
                                            onChose: v => Motion.pick(Store, v, Store.values["animation.curve"] || Motion.CURVE)
                                        }
                                    }
                                    Component {
                                        id: cursors
                                        Pick {
                                            label: "Cursor theme"
                                            options: Store.cursors
                                            current: Store.cursors.find(c => c.toLowerCase() === String(Store.values["cursor.theme"] || "").toLowerCase())
                                            onChose: v => Store.set("cursor.theme", v)
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        acceptedButtons: Qt.RightButton
                                        onClicked: Store.reset(ctl.def.key ?? (ctl.def.type === "cursors" ? "cursor.theme" : "animation"))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: colors
        Column {
            spacing: 8
            TapHandler { acceptedButtons: Qt.RightButton; onTapped: Store.reset("space.world") }
            Row {
                spacing: 12
                Caption { width: 60; caps: true; height: 24; text: "random" }
                Kit.Toggle { on: World.random; onFlip: World.setRandom(!World.random) }
                Button { label: "new world"; onPressed: World.hop(true) }
                Rectangle { width: 12; height: 12; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                Hud {
                    height: 24
                    color: Theme.fg
                    text: World.applied ? World.applied.t.name + "  //  " + World.accentNames[World.applied.i] : World.random ? "random" : Store.colorTheme
                }
            }
            Grid {
                columns: 9
                spacing: 6
                opacity: World.random ? 0.35 : 1
                Behavior on opacity { Settle { duration: Theme.ms(200) } }
                Repeater {
                    model: World.themes
                    Item {
                        id: tile
                        required property var modelData
                        readonly property bool used: World.applied?.t.id === modelData.id
                        readonly property int usedAccent: used ? World.applied.i : -1
                        width: 84
                        height: 112
                        Rectangle {
                            anchors.fill: parent
                            color: Theme.alpha(Theme.accent, tile.used ? 0.1 : ma.containsMouse ? 0.06 : 0.02)
                            border.width: 1
                            border.color: tile.used ? Theme.accent : Theme.alpha(Theme.fg, 0.12)
                            Behavior on color { ColorAnimation { duration: Theme.fast } }
                        }
                        Hud { x: 8; y: 6; font.pixelSize: 9; text: tile.modelData.name; color: tile.used ? Theme.fg : Theme.dim }
                        Column {
                            z: 2
                            x: 8
                            y: 24
                            spacing: 2
                            Repeater {
                                model: [0, 3, 4, 5, 6, 7, 8]
                                Rectangle {
                                    id: sw
                                    required property int modelData
                                    readonly property bool pinned: World.pins[tile.modelData.id] === modelData
                                    width: 68
                                    height: 10
                                    color: tile.modelData.c[modelData]
                                    opacity: World.pins[tile.modelData.id] !== undefined && modelData > 2 && !pinned ? 0.35 : 1
                                    Behavior on opacity { Settle { duration: Theme.ms(140) } }
                                    Hud { visible: sw.pinned || tile.usedAccent === sw.modelData; anchors.centerIn: parent; font.pixelSize: 9; text: sw.pinned ? "accent" : "now"; color: tile.modelData.c[0] }
                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: sw.modelData > 2
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: World.pin(tile.modelData.id, sw.modelData)
                                    }
                                }
                            }
                        }
                        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: World.use(tile.modelData.id, World.pins[tile.modelData.id] ?? 6) }
                    }
                }
            }
        }
    }

    Component {
        id: fonts
        Column {
            id: fontsCol
            spacing: 8
            TapHandler { acceptedButtons: Qt.RightButton; onTapped: Store.reset("space.font") }
            property var all: []
            Process {
                running: true
                command: ["sh", "-c", "fc-list : family | cut -d, -f1 | sort -u"]
                stdout: StdioCollector { onStreamFinished: fontsCol.all = text.split("\n").filter(f => f && !f.startsWith(".")) }
            }
            Row {
                spacing: 14
                Caption { width: 40; caps: true; height: 24; text: "font" }
                Field { id: find; width: 260; placeholder: "search"; keysTo: [sheetKeys]; onAccepted: sheetKeys.forceActiveFocus() }
                Hud { text: Theme.font; height: 24; color: Theme.accent }
            }
            GridView {
                width: 720
                height: 156
                clip: true
                cellWidth: width / 3
                cellHeight: 24
                model: fontsCol.all.filter(f => f.toLowerCase().includes(find.text.toLowerCase()))
                delegate: Item {
                    required property string modelData
                    width: GridView.view.cellWidth
                    height: 24
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 10
                        elide: Text.ElideRight
                        text: parent.modelData
                        font.family: parent.modelData
                        font.pixelSize: 13
                        color: parent.modelData === Theme.font ? Theme.accent : fh.containsMouse ? Theme.fg : Theme.dim
                    }
                    MouseArea { id: fh; anchors.fill: parent; hoverEnabled: true; onClicked: Store.set("space.font", parent.modelData) }
                }
            }
        }
    }

    Component {
        id: profiles
        Row {
            spacing: 24
            ListView {
                id: plist
                width: 320
                height: Math.min(168, Math.max(72, count * 24))
                clip: true
                model: Store.saved.entries.filter(e => e.exists)
                delegate: Kit.Line {
                    required property var modelData
                    property bool armed: false
                    width: 320
                    glyph: modelData.id === Store.saved.active ? "◆" : "◇"
                    text: modelData.name
                    value: armed ? "again to delete" : modelData.kind
                    lit: modelData.id === Store.saved.active
                    onClicked: m => {
                        if (m.button === Qt.LeftButton) return Store.savedRun("apply", modelData.id)
                        if (armed) Store.savedRun("delete", modelData.id)
                        armed = !armed
                    }
                }
            }
            Column {
                spacing: 8
                Hud { text: "save as"; color: Theme.alpha(Theme.fg, 0.35) }
                Field {
                    width: 320
                    placeholder: "name"
                    keysTo: [sheetKeys]
                    onAccepted: { if (text.trim()) Store.savedRun("save", text.trim()); text = ""; sheetKeys.forceActiveFocus() }
                }
            }
        }
    }

    Item {
        id: sheetKeys
        focus: true
        Keys.onEscapePressed: activeFocus ? sheet.close() : forceActiveFocus()
        Keys.onTabPressed: sheet.step(1)
        Keys.onBacktabPressed: sheet.step(-1)
    }
}
