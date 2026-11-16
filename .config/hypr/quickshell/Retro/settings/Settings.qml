import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../shared"
import "../common"
import "../../shared/MotionShared.js" as Motion
import "../common/Schema.js" as Schema

PanelWindow {
    id: sheet

    signal done()
    screen: Ui.target
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region { item: frame }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "retro-panel"
    WlrLayershell.keyboardFocus: Ui.touring ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive
    HyprlandFocusGrab { active: !Ui.touring && !shut.running; windows: [sheet]; onCleared: sheet.close() }

    readonly property var pages: [["core", "Style, bar, font"], ["colors", "Tube or wallpaper"], ["screen", "Filter and glass"],
        ["windows", "Gaps and borders"], ["effects", "Blur and shadow"], ["animations", "Motion and curves"],
        ["input", "Mouse and keys"], ["system", "Display and clock"], ["profiles", "Save your setup"]]
    property string tab: pages.some(p => p[0] === Ui.sheet) ? Ui.sheet : "core"
    readonly property int index: pages.findIndex(p => p[0] === tab)
    readonly property var page: Schema.PAGES.find(p => p.id === tab)
    function step(d) { tab = pages[(index + d + pages.length) % pages.length][0] }

    property real t: 0
    Component.onCompleted: { StoreShared.refresh(); grow.start() }
    NumberAnimation { id: grow; target: sheet; property: "t"; to: 1; duration: Theme.ms(240); easing.type: Easing.OutCubic }
    SequentialAnimation {
        id: shut
        NumberAnimation { target: sheet; property: "t"; to: 0; duration: Theme.ms(160); easing.type: Easing.InCubic }
        ScriptAction { script: sheet.done() }
    }
    function close() { if (!shut.running) { grow.stop(); shut.start() } }
    function open() { shut.stop(); grow.start() }
    function toggle() { shut.running ? open() : close() }

    component Caption: Type { width: 170; height: 22; caps: false; elide: Text.ElideRight; color: Theme.fg }
    component Pick: Item {
        id: pick
        property string label
        property var options: []
        property string key
        property var fallback
        readonly property var raw: StoreShared.values[key]
        property var current: raw === "" || raw === undefined || raw === null ? options.find(o => o.dflt)?.v ?? fallback : raw
        readonly property bool many: options.length > 5
        readonly property int at: Math.max(0, options.findIndex(o => (o.v ?? o) === current))
        signal chose(var v)
        onChose: v => { if (key) StoreShared.set(key, v) }
        function next(d) { const o = options[(at + d + options.length) % options.length]; chose(o.v ?? o) }
        width: parent?.width ?? 340
        implicitHeight: Math.max(22, chips.height)
        Caption { text: pick.label }
        Flow {
            id: chips
            x: 170
            width: pick.width - 170
            spacing: 4
            Repeater {
                model: pick.many ? [pick.options[pick.at]] : pick.options
                Rectangle {
                    id: chip
                    required property var modelData
                    readonly property bool on: (modelData?.v ?? modelData) === pick.current
                    width: word.implicitWidth + 12 + (pick.many ? 26 : 0)
                    height: 22
                    color: on && !pick.many ? Theme.accent : ca.containsMouse ? Theme.low : "transparent"
                    Type { id: word; x: 6; height: parent.height; text: (chip.modelData?.l ?? chip.modelData ?? "") + (pick.many ? "  ◂▸" : ""); color: chip.on && !pick.many ? Theme.bg : pick.many ? Theme.accent : Theme.dim }
                    MouseArea {
                        id: ca
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: m => pick.many ? pick.next(m.button === Qt.RightButton ? -1 : 1) : pick.chose(chip.modelData.v ?? chip.modelData)
                        onWheel: w => { if (pick.many) pick.next(w.angleDelta.y < 0 ? 1 : -1) }
                    }
                }
            }
        }
    }
    component Flip: Item {
        id: tg
        property string label
        property string key
        property bool fallback: true
        property var raises
        readonly property bool on: !!(StoreShared.values[key] ?? fallback)
        width: parent?.width ?? 340
        implicitHeight: 22
        Caption { text: tg.label }
        Controls.Toggle {
            x: 170
            on: tg.on
            text: tg.on ? "on" : "off"
            onFlip: {
                const r = tg.raises, next = { [tg.key]: !tg.on }
                if (!tg.on && r && StoreShared.values[r.key] < r.min) next[r.key] = r.min
                StoreShared.setMany(next)
            }
        }
    }
    component Knob: Item {
        id: knob
        property string key
        property string label
        property string unit
        property real from: 0
        property real to: 1
        property real step: 1
        property real fallback: from
        readonly property real v: StoreShared.values[key] ?? fallback
        readonly property int digits: (String(step).split(".")[1] ?? "").length
        width: parent?.width ?? 340
        implicitHeight: 22
        Caption { text: knob.label }
        Controls.Slide {
            x: 170
            width: knob.width - 170
            scrollable: true
            readout: knob.v.toFixed(knob.digits) + knob.unit
            value: (knob.v - knob.from) / (knob.to - knob.from)
            onMoved: x => StoreShared.set(knob.key, Number((Math.round((knob.from + x * (knob.to - knob.from)) / knob.step) * knob.step).toFixed(knob.digits)))
        }
    }

    Tube {
        id: frame
        anchors.centerIn: parent
        width: Math.min(1180, sheet.width - 60)
        height: Math.min(sheet.height - 80, Math.max(menu.implicitHeight, content.implicitHeight + 70) + 70)
        t: sheet.t

        Box {
            anchors.fill: parent
            double: true
            title: "setup"
            note: "esc-end"
        }
        MouseArea { anchors.fill: parent; onPressed: m => { keys.forceActiveFocus(); m.accepted = false } }

        Column {
            id: menu
            x: 24
            y: 28
            width: 250
            spacing: 2
            Type { text: "select a page:"; caps: false; color: Theme.dim; height: 22 }
            Repeater {
                model: sheet.pages
                Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool on: sheet.tab === modelData[0]
                    width: menu.width
                    height: 34
                    color: on ? Theme.accent : ra.containsMouse ? Theme.low : "transparent"
                    Type { x: 8; y: 2; text: (row.index + 1) + ". " + row.modelData[0]; color: row.on ? Theme.bg : Theme.fg }
                    Type { x: 30; y: 17; caps: false; text: row.modelData[1]; font.pixelSize: Theme.size - 3; color: row.on ? Theme.bg : Theme.dim }
                    MouseArea { id: ra; anchors.fill: parent; hoverEnabled: true; onClicked: sheet.tab = row.modelData[0] }
                }
            }
        }
        Rectangle { x: menu.x + menu.width + 18; y: 24; width: 1; height: frame.height - 48; color: Theme.low }

        Loader {
            id: content
            x: menu.x + menu.width + 40
            y: 28
            width: frame.width - x - 28
            onLoaded: keys.forceActiveFocus()
            sourceComponent: ({ core: core, colors: colors, profiles: profiles })[sheet.tab] ?? pageView
        }
    }

    Component {
        id: core
        Column {
            spacing: 6
            Controls.Title { width: 520; text: "style" }
            Pick {
                width: 520
                label: "Style"
                options: Object.keys(StoreShared.styles).sort()
                current: StoreShared.active.style
                onChose: v => {
                    const vs = StoreShared.styles[v] || []
                    if (v !== StoreShared.active.style) StoreShared.applyProfile(v, vs.includes(StoreShared.active.variant) ? StoreShared.active.variant : vs[0])
                }
            }
            Pick {
                width: 520
                label: "Machine"
                options: StoreShared.styles[StoreShared.active.style] || []
                current: StoreShared.active.variant
                onChose: v => { if (v !== StoreShared.active.variant) StoreShared.applyProfile(StoreShared.active.style, v) }
            }
            Pick {
                width: 520
                label: "Bar"
                options: (StoreShared.quickshell.styles || []).map(s => s.id)
                current: StoreShared.quickshellActive
                onChose: v => { if (v !== StoreShared.quickshellActive) StoreShared.applyQuickshell(v) }
            }
            Item { width: 1; height: 8 }
            Controls.Title { width: 520; text: "type" }
            Knob { width: 520; label: "Text size"; key: "retro.size"; from: 10; to: 22; step: 1; fallback: 14 }
            Item {
                id: fontsBox
                width: 520
                height: 180
                property var all: []
                Process {
                    running: true
                    command: ["sh", "-c", "fc-list :spacing=mono family | cut -d, -f1 | sort -u"]
                    stdout: StdioCollector { onStreamFinished: fontsBox.all = text.split("\n").filter(f => f && !f.startsWith(".")) }
                }
                Caption { text: "Font" }
                GridView {
                    x: 170
                    width: parent.width - 170
                    height: parent.height
                    clip: true
                    cellWidth: width / 2
                    cellHeight: 22
                    model: fontsBox.all
                    delegate: Rectangle {
                        required property string modelData
                        readonly property bool on: modelData === Theme.font
                        width: GridView.view.cellWidth - 4
                        height: 22
                        color: on ? Theme.accent : fh.containsMouse ? Theme.low : "transparent"
                        Text { x: 6; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 10; elide: Text.ElideRight; text: parent.modelData; font.family: parent.modelData; font.pixelSize: 13; color: parent.on ? Theme.bg : Theme.fg }
                        MouseArea { id: fh; anchors.fill: parent; hoverEnabled: true; onClicked: StoreShared.set("retro.font", parent.modelData) }
                    }
                }
            }
            Type { visible: !Qt.fontFamilies().includes("Terminess Nerd Font Mono"); caps: false; text: "tip: sudo pacman -S ttf-terminus-nerd for the real terminal font"; color: Theme.dim; font.pixelSize: Theme.size - 2 }
        }
    }

    Component {
        id: colors
        Column {
            id: cp
            spacing: 10
            readonly property var tubes: ["dark/phosphor", "dark/amber", "dark/cyan", "dark/paper"]
            readonly property var slots: [9, 10, 11, 12, 13, 14, 1, 2, 3, 4, 5, 6]
            readonly property var list: [{ id: "pywal", name: "Wallpaper", palette: StoreShared.pywalPalette }]
                .concat(tubes.map(t => StoreShared.themes.find(x => x.id === t)).filter(t => !!t))
                .concat(StoreShared.themes.filter(t => !tubes.includes(t.id) && t.id !== "dark/space"))
            property var picks: ({})
            FileView {
                path: HyprShared.state + "/color-roles-saved.json"
                watchChanges: true
                printErrors: false
                onFileChanged: reload()
                onLoaded: { try { cp.picks = JSON.parse(text()) } catch (e) {} }
            }
            function slotFor(id) { return id === StoreShared.colorTheme ? Theme.slotOf("accent") : cp.picks[id]?.accent ?? 9 }
            function use(id, slot) {
                const roles = HyprShared.util + "/colors/color-roles.sh", redraw = HyprShared.dir + "/Retro/base/wallpaper.sh"
                if (id !== StoreShared.colorTheme) {
                    cp.queued = slot
                    return StoreShared.applyTheme(id)
                }
                Quickshell.execDetached(["sh", "-c", "\"$0\" set accent \"$1\" && \"$2\" --apply", roles, String(slot), redraw])
            }
            property int queued: -1
            Connections {
                target: StoreShared
                function onThemeApplied() { if (cp.queued >= 0) { const q = cp.queued; cp.queued = -1; cp.use(StoreShared.colorTheme, q) } }
            }

            Controls.Title { width: 680; text: "tubes and schemes" }
            Grid {
                columns: 5
                spacing: 8
                Repeater {
                    model: cp.list
                    Rectangle {
                        id: tile
                        required property var modelData
                        readonly property bool on: StoreShared.colorTheme === modelData.id
                        readonly property var pal: modelData.palette || []
                        readonly property int pick: cp.slotFor(modelData.id)
                        width: 130
                        height: 96
                        color: "transparent"
                        border.width: on ? 2 : 1
                        border.color: on ? Theme.accent : ta.containsMouse ? Theme.line : Theme.low
                        MouseArea { id: ta; anchors.fill: parent; hoverEnabled: true; onClicked: if (!tile.on) cp.use(tile.modelData.id, tile.pick) }
                        Rectangle {
                            x: 6; y: 6
                            width: parent.width - 12
                            height: 30
                            color: tile.pal[0] ?? "#000"
                            Text { anchors.centerIn: parent; text: "> ready_"; font.family: Theme.font; font.pixelSize: 13; color: tile.pal[tile.pick] ?? Theme.accent }
                        }
                        Type { x: 6; y: 40; width: parent.width - 12; elide: Text.ElideRight; text: tile.modelData.name; color: tile.on ? Theme.accent : Theme.fg; font.pixelSize: Theme.size - 2 }
                        Row {
                            x: 6; y: 66
                            spacing: 1
                            Repeater {
                                model: cp.slots
                                Rectangle {
                                    id: sw
                                    required property int modelData
                                    readonly property bool chosen: tile.pick === modelData
                                    width: 9
                                    height: chosen ? 22 : sa.containsMouse ? 18 : 14
                                    y: 22 - height
                                    color: tile.pal[modelData] ?? "#444"
                                    border.width: chosen ? 1 : 0
                                    border.color: Theme.fg
                                    MouseArea { id: sa; anchors.fill: parent; anchors.topMargin: -(22 - parent.height); hoverEnabled: true; onClicked: cp.use(tile.modelData.id, sw.modelData) }
                                }
                            }
                        }
                    }
                }
            }
            Type { caps: false; text: ""; color: Theme.dim; font.pixelSize: Theme.size - 2; width: 680; wrapMode: Text.WordWrap; height: 40 }
        }
    }

    Component {
        id: profiles
        Row {
            spacing: 24
            Column {
                width: 380
                Controls.Title { text: "saved" }
                Repeater {
                    model: StoreShared.saved.entries.filter(e => e.exists)
                    Controls.Line {
                        required property var modelData
                        property bool armed: false
                        lit: modelData.id === StoreShared.saved.active
                        text: modelData.name
                        value: armed ? "rclick again to delete" : modelData.kind
                        onClicked: m => {
                            if (m.button === Qt.LeftButton) return StoreShared.savedRun("apply", modelData.id)
                            if (armed) StoreShared.savedRun("delete", modelData.id)
                            armed = !armed
                        }
                    }
                }
            }
            Column {
                width: 300
                spacing: 8
                Controls.Title { text: "save as" }
                Field {
                    placeholder: "name"
                    keysTo: [keys]
                    onAccepted: { if (text.trim()) StoreShared.savedRun("save", text.trim()); text = ""; keys.forceActiveFocus() }
                }
            }
        }
    }

    Component {
        id: pageView
        Column {
            spacing: 14
            Row {
                visible: sheet.tab === "screen"
                spacing: 6
                Type { width: 170; height: 22; caps: false; text: "Presets"; color: Theme.fg }
                Repeater {
                    model: Schema.PRESETS
                    Button { required property var modelData; label: modelData.l; onPressed: StoreShared.setMany(modelData.v) }
                }
            }
            Row {
                spacing: 32
                Repeater {
                    model: sheet.page?.columns ?? []
                    Column {
                        id: col
                        required property var modelData
                        readonly property var all: modelData.reduce((a, s) => a.concat(s.controls), [])
                        width: all.some(c => c.type === "bezier") ? Math.min(520, content.width - ((sheet.page?.columns.length ?? 1) - 1) * 412) : 380
                        visible: all.some(c => Schema.shown(c, StoreShared.values, StoreShared.caps))
                        spacing: 12
                        Repeater {
                            model: col.modelData
                            Column {
                                id: sec
                                required property var modelData
                                visible: modelData.controls.some(c => Schema.shown(c, StoreShared.values, StoreShared.caps))
                                width: col.width
                                spacing: 3
                                Controls.Title { text: sec.modelData.label }
                                Repeater {
                                    model: sec.modelData.controls
                                    Loader {
                                        id: ctl
                                        required property var modelData
                                        readonly property var def: modelData
                                        width: sec.width
                                        height: item?.implicitHeight ?? 0
                                        visible: Schema.shown(def, StoreShared.values, StoreShared.caps)
                                        active: visible
                                        sourceComponent: ({ slider: slider, toggle: flip, choice: choice, bezier: bezier, animpreset: preset, cursors: cursors })[def.type] ?? null
                                        Component { id: slider; Knob { key: ctl.def.key; label: ctl.def.label; unit: ctl.def.unit; from: ctl.def.min; to: ctl.def.max; step: ctl.def.step; fallback: ctl.def.dflt ?? ctl.def.min } }
                                        Component { id: flip; Flip { key: ctl.def.key; label: ctl.def.label; raises: ctl.def.raises; fallback: ctl.def.dflt ?? true } }
                                        Component { id: choice; Pick { key: ctl.def.key; label: ctl.def.label; options: ctl.def.options } }
                                        Component { id: bezier; SettingBezierShared { flat: true; textSize: Theme.size - 1 } }
                                        Component {
                                            id: preset
                                            Pick {
                                                label: "Preset"
                                                options: Motion.PRESET_OPTIONS
                                                current: StoreShared.values["animation.preset"] || "theme"
                                                onChose: v => Motion.pick(StoreShared, v, StoreShared.values["animation.curve"] || Motion.CURVE)
                                            }
                                        }
                                        Component {
                                            id: cursors
                                            Pick {
                                                label: "Cursor theme"
                                                options: StoreShared.cursors
                                                current: StoreShared.cursors.find(c => c.toLowerCase() === String(StoreShared.values["cursor.theme"] || "").toLowerCase()) ?? ""
                                                onChose: v => StoreShared.set("cursor.theme", v)
                                            }
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            acceptedButtons: Qt.RightButton
                                            onClicked: StoreShared.reset(ctl.def.key ?? (ctl.def.type === "cursors" ? "cursor.theme" : "animation"))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        id: keys
        focus: true
        Keys.onEscapePressed: activeFocus ? sheet.close() : forceActiveFocus()
        Keys.onTabPressed: sheet.step(1)
        Keys.onBacktabPressed: sheet.step(-1)
        Keys.onPressed: e => {
            const n = parseInt(e.text)
            if (n >= 1 && n <= sheet.pages.length) { sheet.tab = sheet.pages[n - 1][0]; e.accepted = true }
        }
    }
}
