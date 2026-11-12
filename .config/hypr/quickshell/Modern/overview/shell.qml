import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import "../../shared"
import "../common"
import "../bar"

ShellRoot {
    id: root

    property bool open: false
    property real t: 0

    onOpenChanged: {
        tween.stop()
        tween.to = open ? 1 : 0
        tween.duration = Theme.ms(open ? 1200 : 450)
        tween.easing.type = open ? Easing.OutCubic : Easing.InOutCubic
        tween.start()
    }
    NumberAnimation { id: tween; target: root; property: "t" }

    Workspaces {
        id: ex
        active: root.open || root.t > 0
    }

    function restore(e, ws, geom) {
        ex.restore(e, ws, geom)
        open = false
    }

    component Mini: Column {
        id: mini
        property string label
        property real cw: 150
        property real ch: 90
        property var dragEntry: null
        property Item ghost: null
        default property alias content: box.data
        property bool renamable: false
        property bool editing: false
        signal picked()
        signal removed()
        signal renamed(string name)
        signal closed()
        spacing: 6

        function stopEditing() {
            if (!editing) return
            editing = false
            closed()
        }

        Item {
            width: mini.cw
            height: mini.ch
            scale: hov.hovered ? 1.03 : 1
            Behavior on scale { SettleShared { duration: Theme.fast } }
            HoverHandler { id: hov }

            ClippingRectangle {
                id: box
                anchors.fill: parent
                radius: Math.min(Theme.rounding, 8)
                color: Theme.alpha(Theme.fg, 0.06)
            }
            Rectangle {
                anchors.fill: parent
                radius: box.radius
                color: "transparent"
                border.width: 1
                border.color: Theme.alpha(Theme.fg, hov.hovered ? 0.25 : 0.1)
                Behavior on border.color { ColorAnimation { duration: Theme.fast } }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                drag.target: mini.dragEntry ? mini.ghost : null
                drag.threshold: 6
                onPressed: mouse => { if (mini.dragEntry && mini.ghost) mini.ghost.start(box, null, mini.dragEntry, mouse.x, mouse.y) }
                drag.onActiveChanged: if (mini.dragEntry && mini.ghost) drag.active ? mini.ghost.dragging = true : mini.ghost.end()
                onClicked: mini.picked()
            }
            IconButtonShared {
                id: closeX
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 6
                text: "\uf00d"
                font.pixelSize: 11
                opacity: hov.hovered ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                hot: Theme.warn
                idle: Theme.bright
                onClicked: mini.removed()
            }
            IconButtonShared {
                visible: mini.renamable
                anchors.right: closeX.left
                anchors.rightMargin: 10
                anchors.verticalCenter: closeX.verticalCenter
                text: "\uf040"
                font.pixelSize: 10
                opacity: hov.hovered ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                idle: Theme.bright
                onClicked: {
                    mini.editing = true
                    field.text = mini.label
                    field.selectAll()
                    field.forceActiveFocus()
                }
            }
        }

        LabelShared {
            visible: !mini.editing
            width: mini.cw
            elide: Text.ElideRight
            text: mini.label
            font.pixelSize: 10
            color: Theme.dim
        }
        TextInput {
            id: field
            visible: mini.editing
            width: mini.cw
            clip: true
            font.family: Theme.sans
            font.pixelSize: 10
            color: Theme.bright
            selectionColor: Theme.alpha(Theme.accent, 0.5)
            onAccepted: { const t = text; mini.stopEditing(); mini.renamed(t) }
            Keys.onEscapePressed: mini.stopEditing()
            onActiveFocusChanged: if (!activeFocus) mini.stopEditing()
            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                z: -1
                radius: Math.min(Theme.rounding, 4)
                color: "transparent"
                border.width: 1
                border.color: Theme.alpha(Theme.accent, 0.6)
            }
        }
    }

    component Heading: LabelShared {
        font.pixelSize: 15
        font.bold: true
        color: Theme.bright
    }

    property var guest: null

    function viewAt(gx, gy) {
        return views.instances.find(v => v.screen && gx >= v.screen.x && gx < v.screen.x + v.screen.width
            && gy >= v.screen.y && gy < v.screen.y + v.screen.height) ?? null
    }

    function special() {
        HyprShared.dispatch("hl.dsp.workspace.toggle_special(\"magic\")", "togglespecialworkspace magic")
        open = false
    }

    IpcHandler {
        target: "overview"
        function toggle(): void { root.open = !root.open }
        function open(): void { root.open = true }
        function close(): void { root.open = false }
    }

    Variants {
        id: views
        model: Quickshell.screens

        PanelWindow {
            id: ov
            visible: root.open || root.t > 0
            required property var modelData
            screen: modelData

            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-overview"
            WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            mask: Region { item: root.open ? backdrop : null }

            readonly property var monitor: Hyprland.monitorFor(screen)
            readonly property int activeId: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : -1
            readonly property var spaces: ex.workspacesOn(screen ? screen.name : "")
            readonly property var tiles: spaces.ids.concat([-1])
            readonly property int cols: tiles.length <= 3 ? tiles.length : tiles.length <= 6 ? 3 : 4
            readonly property real gap: 28
            readonly property int rows: Math.ceil(tiles.length / cols) + 1
            readonly property var geom: ex.geometry(monitor)
            readonly property real tileW: Math.min(560, (width - 160 - (cols - 1) * gap) / cols,
                (height - 260 - (rows - 1) * (gap + 30)) / rows * geom.w / geom.h)
            readonly property var magic: { ex.rev; return Hyprland.workspaces.values.find(w => w.name === "special:magic") ?? null }
            readonly property bool magicUsed: !!magic && ex.windowsOn(magic.id).length > 0
            readonly property bool showsMagic: {
                if (!magicUsed) return true
                const m = magic.monitor ? magic.monitor.name : (magic.lastIpcObject || {}).monitor
                return !m || m === screen.name
            }
            readonly property var pads: ex.scratchpads()

            function pickWindow(t) { ex.focusWindow(t); root.open = false }
            function pickWorkspace(id) { ex.goTo(id); root.open = false }

            property bool hosting: false

            function follow() {
                if (hosting || !proxy.dragging) return
                const gx = screen.x + proxy.x + proxy.Drag.hotSpot.x, gy = screen.y + proxy.y + proxy.Drag.hotSpot.y
                const v = root.viewAt(gx, gy)
                const to = v && v !== ov ? v : null
                if (root.guest && root.guest !== to) root.guest.leave()
                root.guest = to
                if (to) to.host(proxy, gx, gy)
            }
            function host(from, gx, gy) {
                if (!hosting) {
                    hosting = true
                    proxy.width = from.width
                    proxy.height = from.height
                    proxy.toplevel = from.toplevel
                    proxy.entry = from.entry
                    proxy.Drag.hotSpot.x = from.Drag.hotSpot.x
                    proxy.Drag.hotSpot.y = from.Drag.hotSpot.y
                    proxy.shown = from.shown
                    proxy.fromX = 0
                    proxy.fromY = 0
                    proxy.fromW = from.width
                    proxy.fromH = from.height
                }
                proxy.x = gx - screen.x - proxy.Drag.hotSpot.x
                proxy.y = gy - screen.y - proxy.Drag.hotSpot.y
                proxy.dragging = true
            }
            function leave() { proxy.dragging = false; hosting = false }
            function land() { proxy.end(); hosting = false }

            Connections {
                target: proxy
                function onXChanged() { ov.follow() }
                function onYChanged() { ov.follow() }
                function onDraggingChanged() {
                    if (ov.hosting || proxy.dragging || !root.guest) return
                    root.guest.land()
                    root.guest = null
                }
            }

            Backdrop {
                id: backdrop
                anchors.fill: parent
                visible: ex.active
                t: root.t
                source: ex.active && ex.wallpaper !== "" ? "file://" + ex.wallpaper : ""
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
            }

            Item {
                id: keyCatcher
                anchors.fill: parent
                focus: true
                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Escape) root.open = false
                    else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_9) ov.pickWorkspace(e.key - Qt.Key_0)
                    else { e.accepted = false; return }
                    e.accepted = true
                }
            }

            Item {
                anchors.fill: parent
                visible: root.t > 0

                LabelShared {
                    id: hint
                    readonly property real p: Theme.seg(root.t, 0.02)
                    opacity: p
                    transform: Translate { y: (1 - hint.p) * -24 }
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: grid.top
                    anchors.bottomMargin: 26
                    text: "1-9 to jump  ·  Esc to close"
                    font.pixelSize: 11
                    color: Theme.dim
                }

                Grid {
                    id: grid
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Math.max(80, (ov.height - height) / 2 - 120)
                    columns: ov.cols
                    columnSpacing: ov.gap
                    rowSpacing: ov.gap

                    Repeater {
                        model: ov.tiles

                        Column {
                            id: cell
                            required property int modelData
                            required property int index
                            readonly property bool isNew: modelData === -1
                            readonly property int wsId: isNew ? ov.spaces.next : modelData
                            readonly property var windows: ex.windowsOn(wsId)
                            spacing: 10
                            readonly property real p: Theme.seg(root.t, Math.min(0.3, 0.06 + index * 0.04))
                            opacity: p
                            scale: 0.94 + 0.06 * p
                            transform: Translate { y: (1 - cell.p) * 44 }

                            Item {
                                width: ov.tileW
                                height: 18
                                Heading {
                                    text: cell.isNew ? "New" : cell.wsId
                                    color: cell.wsId === ov.activeId ? Theme.accent : Theme.bright
                                }
                                Workspaces.Actions {
                                    visible: !cell.isNew && cell.windows.length > 0
                                    anchors.right: parent.right
                                    expose: ex
                                    wsId: cell.wsId
                                    geom: ov.geom
                                    ids: ov.spaces.ids
                                    activeId: ov.activeId
                                }
                            }

                            Workspaces.SpaceTile {
                                width: ov.tileW
                                big: true
                                expose: ex
                                monitor: ov.monitor
                                wsId: cell.wsId
                                isNew: cell.isNew
                                ghost: proxy
                                takesSaved: cell.isNew || cell.windows.length === 0
                                current: cell.wsId === ov.activeId
                                onWindowPicked: t => ov.pickWindow(t)
                                onWorkspacePicked: id => ov.pickWorkspace(id)
                                onSavedDropped: e => root.restore(e, cell.wsId, ov.geom)
                            }
                        }
                    }
                }

                Row {
                    id: extras
                    readonly property real p: Theme.seg(root.t, 0.2)
                    opacity: p
                    scale: 0.94 + 0.06 * p
                    transform: Translate { y: (1 - extras.p) * 44 }
                    x: grid.x
                    anchors.top: grid.bottom
                    anchors.topMargin: 36
                    spacing: ov.gap

                    Column {
                        visible: ov.showsMagic
                        spacing: 10
                        Item {
                            width: ov.tileW * 0.6
                            height: 18
                            Heading { text: "Special" }
                            Workspaces.Actions {
                                visible: ov.magicUsed
                                anchors.right: parent.right
                                expose: ex
                                wsId: ov.magic ? ov.magic.id : -999
                                geom: ov.geom
                                ids: ov.spaces.ids
                                activeId: ov.activeId
                            }
                        }
                        Workspaces.SpaceTile {
                            width: ov.tileW * 0.6
                            big: true
                            expose: ex
                            monitor: ov.monitor
                            wsId: ov.magic ? ov.magic.id : -999
                            isNew: !ov.magicUsed
                            hint: "Drop a window here"
                            target: "special:magic"
                            ghost: proxy
                            takesSaved: true
                            onWindowPicked: t => ov.pickWindow(t)
                            onWorkspacePicked: root.special()
                            onSavedDropped: e => { ex.restore(e, "special:magic", ov.geom); root.special() }
                        }
                    }

                    Column {
                        opacity: ov.pads.length > 0 ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.move } }
                        spacing: 10
                        Heading { text: "Scratchpads" }
                        Flow {
                            width: 272
                            spacing: 12
                            add: Transition { SettleShared { property: "opacity"; from: 0; to: 1; duration: Theme.move } }
                            move: Transition { SettleShared { properties: "x,y"; duration: Theme.move } }
                            Repeater {
                                model: ScriptModel { values: ov.pads }
                                Mini {
                                    id: pad
                                    required property var modelData
                                    readonly property var o: modelData.lastIpcObject
                                    label: ex.scratchOf(modelData)?.name ?? ""
                                    ch: 70
                                    cw: Math.min(130, 70 * o.size[0] / Math.max(1, o.size[1]))
                                    onPicked: { Quickshell.execDetached(["pypr", "toggle", label]); root.open = false }
                                    onRemoved: ex.closeWindow(modelData)
                                    IconImage {
                                        anchors.centerIn: parent
                                        implicitSize: 32
                                        source: ex.iconFor(pad.o.class)
                                    }
                                    ScreencopyView {
                                        anchors.fill: parent
                                        captureSource: ex.active && !ex.isClosing(pad.modelData) ? pad.modelData.wayland : null
                                        live: ex.active
                                        constraintSize: Qt.size(Math.ceil(pad.cw * 2), 140)
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        opacity: ex.saved.length > 0 ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.move } }
                        spacing: 10
                        Heading { text: "Saved" }
                        Flow {
                            width: 312
                            spacing: 12
                            add: Transition { SettleShared { property: "opacity"; from: 0; to: 1; duration: Theme.move } }
                            move: Transition { SettleShared { properties: "x,y"; duration: Theme.move } }
                            Repeater {
                                model: ScriptModel { values: ex.saved.map(e => e.key) }
                                Mini {
                                    id: entry
                                    required property string modelData
                                    readonly property var ws: ex.byKey[modelData] ?? { name: "", windows: [] }
                                    readonly property real sw: Math.max(ws.w || 0, ...ws.windows.map(w => w.x + w.w))
                                    readonly property real sh: Math.max(ws.h || 0, ...ws.windows.map(w => w.y + w.h))
                                    readonly property real k: Math.min(150 / sw, 90 / sh)
                                    cw: sw * k
                                    ch: sh * k
                                    label: ws.name
                                    dragEntry: ws
                                    Pop { target: entry; label: entry.label }
                                    ghost: proxy
                                    onPicked: root.restore(ws, ex.savedTarget(ov.activeId, ov.spaces.next), ov.geom)
                                    onRemoved: ex.forget(ws)
                                    renamable: true
                                    onRenamed: name => ex.rename(ws, name)
                                    onClosed: keyCatcher.forceActiveFocus()

                                    Image {
                                        anchors.fill: parent
                                        source: ex.wallpaper !== "" ? "file://" + ex.wallpaper : ""
                                        sourceSize.width: 320
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        opacity: 0.6
                                    }
                                    Workspaces.Layout {
                                        anchors.fill: parent
                                        windows: entry.ws.windows
                                        k: entry.k
                                        fill: Theme.back(0.85)
                                        edge: Theme.alpha(Theme.fg, 0.12)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Workspaces.Ghost { id: proxy; previewW: ov.tileW; previewGeom: ov.geom; expose: ex }
        }
    }
}
