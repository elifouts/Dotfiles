import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../shared"
import "../common"

PanelWindow {
    id: pk

    signal done()
    screen: Ui.target
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "retro-panel"
    WlrLayershell.keyboardFocus: Ui.touring ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive

    property real t: 0
    Component.onCompleted: grow.start()
    NumberAnimation { id: grow; target: pk; property: "t"; to: 1; duration: Theme.ms(240); easing.type: Easing.OutCubic }
    SequentialAnimation {
        id: shut
        NumberAnimation { target: pk; property: "t"; to: 0; duration: Theme.ms(160); easing.type: Easing.InCubic }
        ScriptAction { script: pk.done() }
    }
    function close() { if (!shut.running) { grow.stop(); shut.start() } }

    property var all: []
    property string theme: "all"
    readonly property var themes: ["all"].concat(all.some(w => w.fav) ? ["favorites"] : [], [...new Set(all.map(w => w.theme))].sort())
    readonly property var items: theme === "all" ? all : theme === "favorites" ? all.filter(w => w.fav) : all.filter(w => w.theme === theme)
    property int sel: 0
    readonly property var current: items[sel] ?? null
    onThemeChanged: sel = 0
    property string live: ""

    FileView {
        id: idx
        path: HyprShared.home + "/.cache/wallpaper-picker/index.json"
        printErrors: false
        onLoaded: {
            try { pk.all = JSON.parse(text()) } catch (e) {}
            const i = pk.items.findIndex(w => w.path === pk.live)
            if (i >= 0) pk.sel = i
        }
    }
    FileView { path: HyprShared.home + "/.cache/wallpaper-picker/current"; printErrors: false; onLoaded: pk.live = text().trim() }
    Process {
        running: true
        command: ["flock", "-w", "5", (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/wallpaper-index.lock", "python3", HyprShared.util + "/wallpaper/wallpaper-index.py"]
        onExited: idx.reload()
    }

    property string shown: ""
    Timer { id: settle; interval: 220; onTriggered: if (pk.current && !look.running) { look.command = [HyprShared.dir + "/Retro/base/wallpaper.sh", pk.current.path]; look.running = true } }
    onCurrentChanged: settle.restart()
    Process { id: look; stdout: StdioCollector { onStreamFinished: pk.shown = text.trim() } onExited: if (look.command[1] !== pk.current?.path) settle.restart() }

    function apply() {
        if (!current) return
        Quickshell.execDetached([HyprShared.util + "/wallpaper/wallpaper-apply.sh", current.path])
        live = current.path
        close()
    }
    function fav() {
        if (!current) return
        const p = current.path
        all = all.map(w => w.path === p ? Object.assign({}, w, { fav: !w.fav }) : w)
        Quickshell.execDetached([HyprShared.util + "/wallpaper/wallpaper-fav.sh", p])
    }
    function move(d) { sel = Math.max(0, Math.min(items.length - 1, sel + d)) }

    MouseArea { anchors.fill: parent; onClicked: pk.close() }

    Tube {
        id: frame
        anchors.centerIn: parent
        width: Math.min(1400, pk.width - 60)
        height: Math.min(pk.height - 80, 760)
        t: pk.t

        Box { anchors.fill: parent; double: true; title: "screens"; note: "enter-apply  f-favorite  tab-folder  esc-end" }
        MouseArea { anchors.fill: parent }

        Column {
            id: folders
            x: 24; y: 28
            width: 190
            spacing: 2
            Type { text: "folder:"; caps: false; color: Theme.dim; height: 22 }
            Repeater {
                model: pk.themes
                Controls.Line {
                    required property string modelData
                    required property int index
                    width: folders.width
                    glyph: String(index + 1)
                    text: modelData
                    lit: pk.theme === modelData
                    value: String(modelData === "all" ? pk.all.length : modelData === "favorites" ? pk.all.filter(w => w.fav).length : pk.all.filter(w => w.theme === modelData).length)
                    onClicked: pk.theme = modelData
                }
            }
        }

        GridView {
            id: grid
            x: folders.x + folders.width + 20
            y: 28
            width: 4 * 168
            height: frame.height - 56
            clip: true
            cellWidth: 168
            cellHeight: 112
            model: pk.items
            currentIndex: pk.sel
            highlightMoveDuration: 0
            boundsBehavior: Flickable.StopAtBounds
            delegate: Item {
                id: cell
                required property var modelData
                required property int index
                readonly property bool on: index === pk.sel
                width: 168
                height: 112
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    color: cell.on ? Theme.accent : "transparent"
                    border.width: 1
                    border.color: cell.on ? Theme.accent : cell.modelData.path === pk.live ? Theme.line : Theme.low
                    Image {
                        id: img
                        anchors.fill: parent
                        anchors.margins: 3
                        source: "file://" + cell.modelData.thumb
                        sourceSize.width: 160
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: false
                    }
                    MultiEffect {
                        anchors.fill: img
                        source: img
                        colorization: cell.on ? 0.35 : 0.8
                        colorizationColor: Theme.accent
                        brightness: cell.on ? 0 : -0.2
                    }
                    Text { visible: cell.modelData.fav; x: 6; y: 4; text: "★"; font.family: Theme.font; font.pixelSize: Theme.size; color: Theme.accent; style: Text.Outline; styleColor: Theme.bg }
                }
                MouseArea { anchors.fill: parent; onClicked: pk.sel === cell.index ? pk.apply() : pk.sel = cell.index }
            }
        }

        Item {
            x: grid.x + grid.width + 20
            y: 28
            width: frame.width - x - 24
            height: frame.height - 56
            Type { text: "preview"; color: Theme.accent; height: 22 }
            Rectangle {
                id: shot
                y: 26
                width: parent.width
                height: width * 9 / 16
                color: Theme.bg
                border.width: 1
                border.color: Theme.line
                Image {
                    anchors.fill: parent
                    anchors.margins: 1
                    source: pk.shown ? "file://" + pk.shown : ""
                    fillMode: Image.PreserveAspectCrop
                    smooth: false
                    asynchronous: true
                    cache: false
                }
                Type { anchors.centerIn: parent; visible: look.running; text: "rendering"; color: Theme.dim }
            }
            Column {
                y: shot.y + shot.height + 14
                width: parent.width
                spacing: 2
                Repeater {
                    model: pk.current ? [["name", pk.current.name], ["folder", pk.current.theme], ["status", pk.current.path === pk.live ? "on screen" : "standby"]] : []
                    Item {
                        required property var modelData
                        width: parent.width
                        height: 20
                        Type { text: modelData[0]; color: Theme.dim; height: parent.height }
                        Type { anchors.right: parent.right; text: modelData[1]; color: Theme.fg; height: parent.height }
                    }
                }
                Item { width: 1; height: 10 }
                Row {
                    spacing: 8
                    Button { label: "apply"; primary: true; onPressed: pk.apply() }
                    Button { label: pk.current?.fav ? "unfavorite" : "favorite"; onPressed: pk.fav() }
                    Button { label: "filter"; onPressed: { pk.close(); Ui.request("screen") } }
                }
            }
        }
    }

    Item {
        focus: true
        Keys.onEscapePressed: pk.close()
        Keys.onReturnPressed: pk.apply()
        Keys.onEnterPressed: pk.apply()
        Keys.onPressed: e => {
            const k = e.key
            if (k === Qt.Key_Right || e.text === "l") pk.move(1)
            else if (k === Qt.Key_Left || e.text === "h") pk.move(-1)
            else if (k === Qt.Key_Down || e.text === "j") pk.move(4)
            else if (k === Qt.Key_Up || e.text === "k") pk.move(-4)
            else if (k === Qt.Key_Tab) pk.theme = pk.themes[(pk.themes.indexOf(pk.theme) + 1) % pk.themes.length]
            else if (k === Qt.Key_Backtab) pk.theme = pk.themes[(pk.themes.indexOf(pk.theme) - 1 + pk.themes.length) % pk.themes.length]
            else if (e.text === "f") pk.fav()
            else return
            e.accepted = true
        }
    }
}
