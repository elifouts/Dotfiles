import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../common"
import "../ui"
import "Motion.js" as Motion

// hud sheet from the bottom, opens and resizes like modern's pills
PanelWindow {
    id: sheet

    signal done()
    screen: Ui.target
    anchors.bottom: true
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: Math.min(900, (screen?.width ?? 900) - 32)
    // tallest tab, the frame inside eases between heights
    implicitHeight: 500
    color: "transparent"
    mask: Region { item: frame }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "space-settings"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property string tab: Ui.sheet
    readonly property var tabs: ["core", "colors", "fonts", "motion", "profiles"]
    Component.onCompleted: { Store.refresh(); morph.open() }
    function close() { morph.close() }
    Morph { id: morph; openMs: 560; closeMs: 340; onClosed: sheet.done() }
    // the curve editor needs the room
    property real h: tab === "motion" ? 500 : 330
    Behavior on h { Settle { duration: Theme.move } }
    function step(d) {
        tab = tabs[(tabs.indexOf(tab) + d + tabs.length) % tabs.length]
    }
    HyprlandFocusGrab { active: true; windows: [sheet]; onCleared: sheet.close() }

    component Caption: Hud { width: 100; height: 24; color: Theme.alpha(Theme.fg, 0.35) }
    // label left, clickable words right
    component Pick: Row {
        id: pick
        property string label
        property var options: []
        property string key
        property var fallback
        property var current: Store.values[key] || fallback
        signal chose(var v)
        onChose: v => { if (key) Store.set(key, v) }
        height: 24
        spacing: 12
        Caption { text: pick.label }
        Repeater {
            model: pick.options
            Hud {
                required property var modelData
                // plain strings or modern's { v, l } options
                readonly property var v: modelData.v ?? modelData
                text: modelData.l ?? modelData
                height: 24
                color: v === pick.current ? Theme.accent : area.containsMouse ? Theme.fg : Theme.dim
                MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; onClicked: pick.chose(parent.v) }
            }
        }
    }
    component Toggle: Row {
        id: tg
        property string label
        property string key
        property bool fallback: true
        height: 24
        spacing: 12
        Caption { text: tg.label }
        Kit.Toggle {
            // hyprland reports its bools as 1/0 sometimes, so coerce
            on: !!(Store.values[tg.key] ?? tg.fallback)
            onFlip: Store.set(tg.key, !on)
        }
    }
    // a Kit slider mapped onto a real range
    component Knob: Row {
        id: knob
        property string key
        property string label
        property real from: 0
        property real to: 1
        property real step: 1
        property real fallback: 0
        readonly property real v: Store.values[key] ?? fallback
        height: 22
        spacing: 12
        Caption { text: knob.label; height: 22 }
        Kit.Slide {
            width: 230
            value: (knob.v - knob.from) / (knob.to - knob.from)
            onMoved: x => Store.set(knob.key, Math.round((knob.from + x * (knob.to - knob.from)) / knob.step) * knob.step)
        }
    }

    // a strip that widens out of the bottom edge, then opens up
    Rectangle {
        id: frame
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -(1 - morph.rise) * 18
        anchors.horizontalCenter: parent.horizontalCenter
        width: 44 + (sheet.width - 44) * Math.min(1, morph.mw)
        height: 10 + (sheet.h - 10) * Math.min(1, morph.mh)
        opacity: Math.min(1, morph.t * 6)
        clip: true
        color: Theme.alpha(Theme.bg, 0.8)
        border.width: 1
        border.color: Theme.alpha(Theme.accent, 0.3)
        Rectangle { width: parent.width; height: 2; color: Theme.accent }

        // laid out at full size and pinned to the top, so it unrolls instead of squishing
        Item {
            x: (parent.width - width) / 2
            width: sheet.width
            height: sheet.h
            opacity: morph.stage(0.5)

            Row {
                x: 24
                y: 14
                spacing: 22
                Repeater {
                    model: sheet.tabs
                    Hud {
                        required property string modelData
                        text: modelData
                        font.pixelSize: 12
                        color: sheet.tab === modelData ? Theme.accent : Theme.dim
                        Rectangle { anchors.top: parent.bottom; anchors.topMargin: 4; width: parent.width; height: 1; color: Theme.accent; visible: sheet.tab === parent.modelData }
                        MouseArea { anchors.fill: parent; onClicked: sheet.tab = parent.modelData }
                    }
                }
            }
            Hud { anchors.right: parent.right; anchors.rightMargin: 24; y: 14; text: "esc"; color: Theme.alpha(Theme.fg, 0.25) }

            Loader {
                x: 24
                y: 50
                width: parent.width - 48
                height: parent.height - 62
                sourceComponent: ({ colors: colors, fonts: fonts, motion: motion, profiles: profiles })[sheet.tab] ?? core
            }
        }
    }

    Component {
        id: core
        Row {
            spacing: 40
            Column {
                spacing: 3
                Pick {
                    label: "style"
                    options: Object.keys(Store.styles).sort()
                    current: Store.active.style
                    onChose: v => {
                        const vs = Store.styles[v] || []
                        if (v !== Store.active.style) Store.applyProfile(v, vs.includes(Store.active.variant) ? Store.active.variant : vs[0])
                    }
                }
                Pick {
                    label: "machine"
                    options: Store.styles[Store.active.style] || []
                    current: Store.active.variant
                    onChose: v => { if (v !== Store.active.variant) Store.applyProfile(Store.active.style, v) }
                }
                Pick { label: "layout"; options: ["dwindle", "master"]; key: "config.general.layout" }
                Toggle { label: "glow"; key: "config.decoration.glow.enabled" }
                Toggle { label: "blur"; key: "config.decoration.blur.enabled" }
                Toggle { label: "24h clock"; key: "space.clock24" }
                Toggle { visible: !!Store.caps.touchpad; label: "natural scroll"; key: "config.input.touchpad.natural_scroll" }
            }
            Column {
                spacing: 4
                Knob { label: "gaps in"; key: "config.general.gaps_in"; to: 20; fallback: 4 }
                Knob { label: "gaps out"; key: "config.general.gaps_out"; to: 40; fallback: 12 }
                Knob { label: "border"; key: "config.general.border_size"; to: 4; fallback: 1 }
                Knob { label: "rounding"; key: "config.decoration.rounding"; to: 20; fallback: 3 }
                Knob { label: "mouse speed"; key: "config.input.sensitivity"; from: -1; to: 1; step: 0.05 }
                Knob { label: "pan distance"; key: "space.parallax"; from: 0.2; to: 2; step: 0.1; fallback: 1 }
            }
        }
    }

    // nine themes. the planets draw their colours from whichever are lit, or from anywhere when random is on
    Component {
        id: colors
        Column {
            spacing: 14
            Row {
                spacing: 12
                Caption { text: "random" }
                Kit.Toggle { on: World.random; onFlip: World.setRandom(!World.random) }
                Item { width: 24; height: 1 }
                Button { label: "new world"; onPressed: World.reroll() }
                Hud { height: 24; color: Theme.alpha(Theme.fg, 0.3); text: World.random ? "any colour goes" : "swatch pins accent  //  tile adds or drops it" }
            }
            // what's actually on the desktop right now
            Row {
                spacing: 12
                Caption { text: "applied"; height: 14 }
                Rectangle { width: 14; height: 14; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                Hud {
                    height: 14
                    color: Theme.fg
                    text: World.applied ? World.applied.t.name + "  //  " + World.accentNames[World.applied.i] : World.random ? "random" : Store.colorTheme
                }
            }
            Grid {
                columns: 9
                spacing: 6
                opacity: World.random ? 0.35 : 1
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Repeater {
                    model: World.themes
                    Item {
                        id: tile
                        required property var modelData
                        readonly property bool on: World.themeOn(modelData.id)
                        readonly property bool used: World.applied?.t.id === modelData.id
                        readonly property int usedAccent: used ? World.applied.i : -1
                        width: 88
                        height: 150
                        Rectangle {
                            anchors.fill: parent
                            color: Theme.alpha(Theme.accent, tile.on ? 0.1 : ma.containsMouse ? 0.06 : 0.02)
                            border.width: 1
                            border.color: tile.used ? Theme.accent : tile.on ? Theme.alpha(Theme.accent, 0.45) : Theme.alpha(Theme.fg, 0.12)
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }
                        Hud { x: 8; y: 8; font.pixelSize: 9; text: tile.modelData.name; color: tile.on ? Theme.fg : Theme.dim }
                        Column {
                            z: 2
                            x: 8
                            y: 30
                            spacing: 2
                            Repeater {
                                model: [0, 3, 4, 5, 6, 7, 8]
                                Rectangle {
                                    id: sw
                                    required property int modelData
                                    readonly property bool pinned: World.pins[tile.modelData.id] === modelData
                                    width: 72
                                    height: 12
                                    color: tile.modelData.c[modelData]
                                    opacity: World.pins[tile.modelData.id] !== undefined && modelData > 2 && !pinned ? 0.35 : 1
                                    Behavior on opacity { NumberAnimation { duration: 140 } }
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
                        Rectangle { x: 8; y: 128; width: 72; height: 2; color: tile.on ? Theme.accent : "transparent" }
                        Hud { x: 8; y: 133; font.pixelSize: 9; text: tile.used ? "applied" : tile.on ? "in pool" : "off"; color: tile.on ? Theme.accent : Theme.alpha(Theme.fg, 0.3) }
                        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: World.toggleTheme(tile.modelData.id) }
                    }
                }
            }
        }
    }

    // modern's animations page, same presets and curve editor
    Component {
        id: motion
        Column {
            id: mo
            spacing: 6
            readonly property bool on: !!(Store.values["config.animations.enabled"] ?? true)
            readonly property bool own: on && (Store.values["animation.preset"] || "theme") !== "theme"
            Row {
                spacing: 40
                Column {
                    id: knobs
                    spacing: 3
                    Toggle { label: "motion"; key: "config.animations.enabled" }
                    Toggle { label: "shell motion"; key: "utilities.animations"; fallback: false }
                    Toggle { label: "resizes"; key: "config.misc.animate_manual_resizes"; fallback: false }
                    Toggle { label: "dragging"; key: "config.misc.animate_mouse_windowdragging"; fallback: false }
                    Knob { visible: mo.own; label: "speed"; key: "animation.speed"; from: 0.3; to: 2.5; step: 0.05; fallback: 1 }
                }
                SettingBezier { visible: mo.on; width: sheet.width - 48 - knobs.width - 40 }
            }
            Pick {
                visible: mo.on
                label: "preset"
                options: Motion.PRESET_OPTIONS
                current: Store.values["animation.preset"] || "theme"
                onChose: v => Motion.pick(Store, v, Store.values["animation.curve"] || Motion.CURVE)
            }
            Pick { visible: mo.own; label: "windows"; options: Motion.WINDOWS; key: "animation.window"; fallback: "popin 90%" }
            Pick { visible: mo.own; label: "workspaces"; options: Motion.WORKSPACES; key: "animation.workspace"; fallback: "slide" }
        }
    }

    // every installed family, each one drawn in itself
    Component {
        id: fonts
        Column {
            id: fontsCol
            spacing: 8
            property var all: []
            Process {
                running: true
                command: ["sh", "-c", "fc-list : family | cut -d, -f1 | sort -u"]
                stdout: StdioCollector { onStreamFinished: fontsCol.all = text.split("\n").filter(f => f && !f.startsWith(".")) }
            }
            Row {
                spacing: 14
                Caption { text: "font" }
                Field { id: find; width: 260; placeholder: "search" }
                Hud { text: Theme.font; height: 24; color: Theme.accent }
            }
            GridView {
                width: sheet.width - 48
                height: 200
                clip: true
                cellWidth: width / 3
                cellHeight: 26
                model: fontsCol.all.filter(f => f.toLowerCase().includes(find.text.toLowerCase()))
                delegate: Item {
                    required property string modelData
                    width: GridView.view.cellWidth
                    height: 26
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

    // saved profiles, click to jump, right click twice deletes
    Component {
        id: profiles
        Row {
            spacing: 40
            ListView {
                id: plist
                width: 320
                height: 230
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
                    width: 240
                    placeholder: "name"
                    onAccepted: { if (text.trim()) Store.savedRun("save", text.trim()); text = "" }
                }
            }
        }
    }

    Item {
        focus: true
        Keys.onEscapePressed: sheet.close()
        Keys.onTabPressed: sheet.step(1)
        Keys.onBacktabPressed: sheet.step(-1)
    }
}
