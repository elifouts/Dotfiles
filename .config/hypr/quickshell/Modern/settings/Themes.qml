import QtQuick
import Quickshell
import Quickshell.Io
import "../../shared"
import "../common"

Item {
    id: tp

    readonly property var entries: {
        const p = StoreShared.pywalPalette
        const pywal = p.length >= 16 ? [{ id: "pywal", name: "Pywal", palette: full(p.slice(0, 16)) }] : []
        return pywal.concat(StoreShared.themes)
    }
    readonly property var slotNames: Array.from({ length: 16 }, (_, i) => "color" + i)
    readonly property var hints: [["bg", "background, darkest"], ["red", "red, errors"], ["green", "green, strings"],
        ["yellow", "yellow, warnings"], ["blue", "blue, functions"], ["magenta", "magenta, keywords"], ["cyan", "cyan, info"],
        ["text", "text, light gray"], ["dim", "comments, dim gray"], ["accent", "accent, warm red/orange"], ["green+", "bright green"],
        ["yellow+", "bright yellow"], ["blue+", "bright blue"], ["second", "2nd accent, bright magenta"], ["cyan+", "bright cyan"],
        ["white", "brightest text"]]
    function full(p) { return p.concat([p[0], p[15], p[15]]) }
    property int cur: 0
    TapHandler { acceptedButtons: Qt.RightButton; enabled: !tp.draft; onTapped: Theme.setRole() }
    readonly property var entry: entries[cur] ?? { id: "", name: "", palette: [] }
    property var draft: null
    property string draftName: ""
    property int slot: 1
    property bool all16: false
    readonly property var compact: [0, 1, 2, 3, 4, 5, 6, 7]
    readonly property var slots: all16 || draft ? Array.from({ length: 16 }, (_, i) => i) : compact
    readonly property var shown: draft ? full(draft.map(c => c || "#808080")) : entry.palette
    readonly property color picked: draft ? draft[slot] || "#808080" : "black"
    readonly property real r: Math.min(Theme.rounding, 10)

    property var from: []
    property var to: []
    property real k: 1
    property bool instant: false
    onShownChanged: {
        from = instant ? shown.slice() : live
        instant = false
        to = shown.slice()
        k = 0
        fade.restart()
    }
    NumberAnimation { id: fade; target: tp; property: "k"; to: 1; duration: Theme.ms(280); easing.type: Easing.OutCubic }
    readonly property var live: to.map((c, i) => from[i] && from[i] !== c ? String(Theme.along([from[i], c], k)) : c)
    function lc(i) { return live[i] ?? "#888888" }
    readonly property color bg: lc(16)
    readonly property color fg: lc(7)

    function sync() {
        const i = entries.findIndex(e => e.id === StoreShared.colorTheme)
        if (i >= 0 && !draft && !listHover.hovered) cur = i
    }
    onEntriesChanged: sync()
    property real settle: 1
    NumberAnimation { id: jumble; target: tp; property: "settle"; from: 0; to: 1; duration: Theme.ms(650); easing.type: Easing.OutCubic }
    onCurChanged: jumble.restart()
    Timer { id: back; interval: 140; onTriggered: tp.sync() }
    Connections { target: StoreShared; function onColorThemeChanged() { tp.sync() } }

    function step(d) { if (!draft && entries.length) cur = (cur + d + entries.length) % entries.length }
    function pick() { draft ? save() : StoreShared.applyTheme(entry.id) }
    Component.onCompleted: { sync(); StoreShared.picker = tp }
    Component.onDestruction: if (StoreShared.picker === tp) StoreShared.picker = null

    property string editing: ""
    function create(e) {
        instant = true
        draft = e ? e.palette.slice(0, 16) : Array(16).fill("")
        jumble.restart()
        draftName = e ? (e.custom ? e.name : e.name + " copy") : ""
        editing = e && e.custom ? e.id : ""
        slot = 0
    }
    function setSlot(c) {
        const d = draft.slice()
        d[slot] = String(c)
        instant = true
        draft = d
    }
    Process {
        id: eyedropper
        command: ["sh", "-c", 'm=$(mktemp); f=~/.cache/colorpicker/colors; ~/.config/waybar/scripts/colorpicker.sh >/dev/null 2>&1; [ "$f" -nt "$m" ] && head -n1 "$f"; rm -f "$m"']
        stdout: StdioCollector { onStreamFinished: if (tp.draft && /^#[0-9a-f]{6}$/i.test(text.trim())) tp.setSlot(text.trim().toLowerCase()) }
    }

    function save(asNew) {
        const empty = draft.indexOf("")
        if (empty >= 0) { slot = empty; return }
        const name = draftName.trim() || "Custom"
        const base = (Qt.color(draft[0]).hslLightness > 0.5 ? "light/" : "dark/")
            + (name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "") || "custom")
        const over = editing !== "" && !asNew
        let id = over ? editing : base
        for (let n = 2; !over && entries.some(e => e.id === id); n++) id = base + "-" + n
        const colors = {}
        draft.forEach((c, i) => colors["color" + i] = c)
        run(id, ["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1"', "sh", file(id),
            JSON.stringify({ name: name, custom: true, special: { background: draft[0], foreground: draft[15], cursor: draft[15] }, colors: colors })])
        draft = null
    }
    property string role: "accent"
    function remove(e) { run(e.id === StoreShared.colorTheme ? "pywal" : "", ["rm", "-f", file(e.id)]) }
    function file(id) { return Quickshell.env("HOME") + "/.config/wal/colorschemes/" + id + ".json" }
    function run(then, cmd) { writer.then = then; writer.command = cmd; writer.running = true }
    Process {
        id: writer
        property string then
        onExited: { if (then) StoreShared.applyTheme(then); StoreShared.refresh() }
    }

    function t(s) { return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;") }
    function j(s) {
        const n = settle
        return t(n < 1 ? s.replace(/\S/g, ch => Math.random() < n ? ch : "!<>-_/[]{}=+*^?#01"[Math.floor(Math.random() * 18)]) : s)
    }
    function c(i, s) { return span(i, t(s)) }
    function span(i, h) { return "<font color='" + lc(i) + "'>" + h + "</font>" }

    component Field: Rectangle {
        property string value
        property string hint
        readonly property alias text: input.text
        signal done()
        signal edited()
        onValueChanged: if (value !== input.text) input.text = value
        Component.onCompleted: input.text = value
        height: 30
        radius: tp.r
        color: Theme.alpha(Theme.fg, 0.05)
        border.width: 1
        border.color: input.activeFocus ? Theme.accent : Theme.alpha(Theme.fg, 0.12)
        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            verticalAlignment: TextInput.AlignVCenter
            selectByMouse: true
            clip: true
            font.family: Theme.sans
            font.pixelSize: 12
            color: Theme.bright
            selectionColor: Theme.alpha(Theme.accent, 0.5)
            onTextEdited: parent.edited()
            onEditingFinished: { text = parent.value; parent.done() }
            Keys.onEscapePressed: tp.draft = null
        }
        LabelShared {
            visible: !input.text
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 20
            elide: Text.ElideRight
            text: parent.hint
            font.pixelSize: 12
            color: Theme.dim
        }
    }

    Column {
        id: body
        anchors.fill: parent
        anchors.margins: Theme.pad
        spacing: 14

        Rectangle {
            id: term
            width: parent.width
            height: stack.implicitHeight + 24
            Behavior on height { SettleShared { duration: Theme.move } }
            radius: tp.r
            clip: true
            color: tp.bg
            border.width: 1
            border.color: Theme.alpha(Theme.fg, 0.14)
            Rise { target: term; replay: StoreShared.opened }

            Column {
                id: stack
                x: 14
                y: 12
                width: parent.width - 28

                LabelShared {
                    width: parent.width
                    textFormat: Text.StyledText
                    lineHeight: 1.35
                    font.pixelSize: 12
                    color: tp.fg
                    text: tp.c(4, "~/themes") + " " + tp.c(9, "❯") + tp.t(" wal --theme ") + tp.j((tp.draft ? tp.draftName : tp.entry.name).toLowerCase().replace(/ /g, "-")) + "<br>"
                        + tp.c(13, "fn") + " " + tp.c(12, "apply") + tp.t("(scheme: ") + tp.c(14, "&[Rgb; 16]") + tp.t(") {") + "<br>"
                        + "&nbsp;&nbsp;" + tp.c(13, "let") + tp.t(" glow = ") + tp.c(3, "0.35") + tp.t("; ") + tp.span(8, tp.t("// ") + tp.j(tp.draft ? tp.slotNames[tp.slot] + " is " + tp.hints[tp.slot][1] : tp.entry.id === "pywal" ? "from the wallpaper" : tp.entry.custom ? "yours" : "stock")) + "<br>"
                        + "&nbsp;&nbsp;" + tp.c(1, "panic!") + tp.t("(") + tp.c(2, "\"warn\"") + tp.t(");") + "<br>"
                        + "&nbsp;&nbsp;" + tp.c(13, "return") + " " + tp.c(Theme.slotOf("accent"), "\"" + tp.lc(Theme.slotOf("accent")) + "\"") + tp.t("; ") + tp.span(8, tp.t("// accent")) + "<br>"
                        + tp.t("}") + " " + tp.c(18, "▌")
                }

                Item {
                    width: parent.width
                    height: 46
                    Button {
                        visible: !tp.draft
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 8
                        tone: tp.fg
                        label: tp.all16 ? "fewer ▴" : "all 16 ▾"
                        onPressed: tp.all16 = !tp.all16
                    }
                }

                Grid {
                    id: grid
                    width: parent.width
                    columns: 8
                    columnSpacing: 4
                    rowSpacing: 6
                    Repeater {
                        model: tp.slots
                        Column {
                            id: cell
                            required property int modelData
                            required property int index
                            readonly property int s: modelData
                            readonly property bool on: !!tp.draft && tp.slot === s
                            width: (grid.width - 7 * grid.columnSpacing) / 8
                            spacing: 3
                            Rise { target: cell; index: cell.index }
                            Rectangle {
                                width: parent.width
                                height: 16
                                radius: Math.min(Theme.rounding, 4)
                                color: tp.lc(cell.s)
                                border.width: cell.on ? 2 : 1
                                border.color: cell.on ? tp.fg : Theme.alpha(tp.fg, 0.15)
                                HoverShared {
                                    anchors.fill: parent
                                    enabled: !!tp.draft
                                    onClicked: tp.slot = cell.s
                                }
                            }
                            LabelShared {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: tp.draft && !tp.draft[cell.s] ? tp.hints[cell.s][0] : tp.lc(cell.s).slice(1)
                                font.pixelSize: 9
                                color: tp.lc(15)
                                opacity: cell.on ? 1 : 0.45
                            }
                        }
                    }
                }
            }
        }

        ListView {
            id: list
            visible: !tp.draft
            width: parent.width
            height: body.height - term.height - roleBox.height - add.height - body.spacing * 3
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: tp.entries
            currentIndex: tp.cur
            highlightMoveDuration: Theme.ms(160)
            highlightResizeDuration: 0
            Rise { target: list; index: 1; replay: StoreShared.opened }
            HoverHandler {
                id: listHover
                onPointChanged: {
                    const i = list.indexAt(point.position.x, point.position.y)
                    if (i >= 0) { back.stop(); tp.cur = i }
                }
                onHoveredChanged: hovered ? back.stop() : back.restart()
            }
            highlight: Rectangle {
                radius: tp.r
                color: Theme.alpha(Theme.fg, 0.1)
            }

            delegate: Item {
                id: row
                required property var modelData
                required property int index
                readonly property bool on: modelData.id === StoreShared.colorTheme
                width: list.width
                height: 32

                Rectangle {
                    anchors.fill: parent
                    radius: tp.r
                    color: Theme.soft(Theme.accent, rowArea.containsMouse)
                    opacity: row.on ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.ms(120) } }
                }

                HoverShared {
                    id: rowArea
                    anchors.fill: parent
                    onClicked: StoreShared.applyTheme(row.modelData.id)
                }
                LabelShared {
                    x: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.name.toLowerCase()
                    font.pixelSize: 12
                    color: row.on ? Theme.ink : row.index === tp.cur ? Theme.bright : Theme.fg
                }
                Row {
                    visible: rowArea.containsMouse || editBtn.hovered || rmBtn.hovered
                    anchors.right: swatches.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                    IconButtonShared { id: editBtn; text: "edit"; font.pixelSize: 10; onClicked: tp.create(row.modelData) }
                    IconButtonShared {
                        id: rmBtn
                        visible: !!row.modelData.custom
                        text: "rm"
                        font.pixelSize: 10
                        hot: Theme.warn
                        onClicked: tp.remove(row.modelData)
                    }
                }
                Row {
                    id: swatches
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    Repeater {
                        model: tp.compact.map(i => row.modelData.palette[i])
                        Rectangle {
                            required property var modelData
                            width: 12
                            height: 12
                            color: modelData
                        }
                    }
                }
            }
        }

        Column {
            id: roleBox
            visible: !tp.draft
            width: parent.width
            spacing: 8
            Rise { target: roleBox; index: 2; replay: StoreShared.opened }
            Segmented {
                width: parent.width
                options: [{ v: "accent", l: "primary" }, { v: "accent2", l: "second" }, { v: "ok", l: "ok" },
                    { v: "caution", l: "caution" }, { v: "info", l: "info" }, { v: "warn", l: "warn" }]
                current: tp.role
                onPicked: v => tp.role = v
            }
            Row {
                spacing: 4
                Repeater {
                    model: 16
                    Rectangle {
                        required property int index
                        readonly property bool on: Theme.slotOf(tp.role) === index
                        width: (roleBox.width - 15 * 4) / 16
                        height: 16
                        radius: Math.min(Theme.rounding, 4)
                        color: tp.lc(index)
                        border.width: on ? 2 : 1
                        border.color: on ? Theme.bright : Theme.alpha(Theme.fg, 0.15)
                        HoverShared { anchors.fill: parent; onClicked: Theme.setRole(tp.role, index) }
                    }
                }
            }
        }

        IconButtonShared {
            id: add
            visible: !tp.draft
            text: "+ new theme"
            font.pixelSize: 12
            onClicked: tp.create()
            Rise { target: add; index: 3; replay: StoreShared.opened }
        }

        Column {
            visible: !!tp.draft
            width: parent.width
            spacing: 12

            Row {
                width: parent.width
                spacing: 8
                Field {
                    width: (parent.width - 16 - dropper.width) * 0.35
                    value: tp.draft ? tp.draft[tp.slot] : ""
                    hint: tp.draft ? tp.hints[tp.slot][1] : ""
                    onEdited: {
                        const h = text.trim().replace("#", "").toLowerCase()
                        if (/^[0-9a-f]{6}$/.test(h)) tp.setSlot("#" + h)
                    }
                }
                IconButtonShared {
                    id: dropper
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰈊"
                    font.pixelSize: 16
                    onClicked: eyedropper.running = true
                }
                Field {
                    width: (parent.width - 16 - dropper.width) * 0.65
                    hint: "theme name"
                    value: tp.draftName
                    onEdited: tp.draftName = text
                    onDone: tp.save()
                }
            }

            Repeater {
                model: [["hue", "hslHue"], ["sat", "hslSaturation"], ["light", "hslLightness"]]
                Row {
                    required property var modelData
                    required property int index
                    readonly property real v: Math.max(0, tp.picked[modelData[1]])
                    width: parent.width
                    spacing: 10
                    LabelShared {
                        width: 44
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData[0]
                        font.pixelSize: 11
                        color: Theme.dim
                    }
                    Slider {
                        width: parent.width - 98
                        anchors.verticalCenter: parent.verticalCenter
                        step: 0.01
                        value: parent.v
                        onMoved: v => {
                            const c = tp.picked, h = [Math.max(0, c.hslHue), c.hslSaturation, c.hslLightness]
                            h[index] = v
                            tp.setSlot(Qt.hsla(h[0], h[1], h[2], 1))
                        }
                    }
                    LabelShared {
                        width: 34
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignRight
                        text: Math.round(parent.v * (index === 0 ? 360 : 100))
                        font.pixelSize: 11
                        color: Theme.fg
                    }
                }
            }

            Row {
                anchors.right: parent.right
                spacing: 18
                IconButtonShared { text: "esc cancel"; font.pixelSize: 12; onClicked: tp.draft = null }
                IconButtonShared { visible: tp.editing !== ""; text: "save as new"; font.pixelSize: 12; onClicked: tp.save(true) }
                IconButtonShared { text: "↵ save"; font.pixelSize: 12; idle: Theme.accent; hot: Theme.bright; onClicked: tp.save() }
            }
        }
    }
}
