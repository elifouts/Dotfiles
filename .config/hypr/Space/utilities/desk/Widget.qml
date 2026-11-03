import QtQuick
import QtQuick.Effects
import Quickshell
import "../common"
import "../ui"
import "../media"

// one widget, d is its saved entry
Item {
    id: w

    required property var d
    property bool editing: false
    signal noteEdited(string text)

    // set while the corner handle drags
    property real live: 0
    readonly property real s: live || (d.s ?? 1)
    readonly property real pad: d.style === "frame" ? 14 * s : 0
    readonly property color ink: d.style === "glow" ? Theme.accent : Theme.fg
    readonly property var player: d.type === "media" || d.type === "viz" ? Media.pickPlayer("") : null
    implicitWidth: body.width + pad * 2
    implicitHeight: body.height + pad * 2
    // media and viz hide when nothing plays, unless you're placing them
    visible: editing || (d.type !== "media" && d.type !== "viz") || !!player

    SystemClock { id: clock; precision: d.type === "clock" ? SystemClock.Minutes : SystemClock.Hours }
    readonly property bool h24: Store.values["space.clock24"] !== false

    // text, size, how bright
    readonly property var lines: {
        const day = Qt.formatDate(clock.date, "ddd · dd MMM")
        switch (d.type) {
        case "clock": return [[Qt.formatTime(clock.date, h24 ? "HH:mm" : "h:mm"), 64, 1], [day, 12, 0.6]]
        case "stats": return [["cpu " + Math.round(Sys.cpu * 100) + "%  ·  ram " + Math.round(Sys.ram * 100) + "%", 13, 1],
                              [Sys.net + (Power.hasBattery ? "  ·  bat " + Math.round(Power.charge * 100) + "%" : ""), 11, 0.6]]
        }
        return []
    }

    // corner brackets, the hud way of saying "box"
    Repeater {
        model: d.style === "frame" ? 4 : 0
        Item {
            required property int index
            readonly property bool r: index % 2 === 1
            readonly property bool b: index > 1
            x: r ? w.width - 10 : 0
            y: b ? w.height - 10 : 0
            width: 10
            height: 10
            Rectangle { width: 10; height: 1; y: parent.b ? 9 : 0; color: Theme.alpha(Theme.accent, 0.7) }
            Rectangle { width: 1; height: 10; x: parent.r ? 9 : 0; color: Theme.alpha(Theme.accent, 0.7) }
        }
    }
    Rectangle {
        anchors.fill: parent
        visible: d.style === "frame"
        color: Theme.alpha(Theme.bg, 0.25)
    }

    Column {
        id: body
        x: w.pad
        y: w.pad
        spacing: 2 * w.s
        // glow only on glow widgets, the rest cost nothing
        layer.enabled: d.style === "glow"
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.accent
            shadowBlur: 0.7
            shadowOpacity: 0.7
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
        }

        Repeater {
            model: w.lines
            Hud {
                caps: false
                required property var modelData
                x: w.d.align === "center" ? (body.width - width) / 2 : w.d.align === "right" ? body.width - width : 0
                text: modelData[0]
                font.family: Theme.font
                font.pixelSize: modelData[1] * w.s
                font.weight: modelData[1] > 30 ? Font.ExtraLight : Font.Normal
                font.letterSpacing: modelData[1] > 30 ? 2 * w.s : 1.6 * w.s
                font.capitalization: modelData[1] > 30 ? Font.MixedCase : Font.AllUppercase
                color: Theme.alpha(w.ink, modelData[2])
            }
        }

        MediaCtl {
            visible: w.d.type === "media"
            width: 300 * w.s
            s: w.s
            ink: w.ink
        }

        // the same little visualizer the bar used to have, just bigger
        MiniWave {
            visible: w.d.type === "viz"
            bars: 32
            barWidth: 4 * w.s
            reach: 56 * w.s
            height: (56 + 8) * w.s
            playing: visible && Media.playing(w.player)
        }

        // modern's calendar + todos, loaded so other widgets skip the month grid
        Loader {
            active: w.d.type === "todo"
            visible: active
            sourceComponent: Item {
                width: cal.width * w.s
                height: cal.implicitHeight * w.s
                                readonly property string here: QsWindow.window?.screen?.name ?? ""
                Calendar {
                    id: cal
                    width: 300
                    open: true
                    // being placed, clicks go to the drag
                    enabled: !w.editing
                    scale: w.s
                    transformOrigin: Item.TopLeft
                    onTypingChanged: Ui.typing = typing ? parent.here : ""
                }
                // drop the keys if the mouse wanders off
                HoverHandler { id: inside }
                Timer { interval: 1500; running: cal.typing && !inside.hovered; onTriggered: cal.letGo() }
            }
        }

        TextEdit {
            visible: w.d.type === "note"
            width: Math.max(140 * w.s, implicitWidth)
            text: w.d.text ?? "note"
            readOnly: !w.editing
            // mouse selection held the grab so the widget couldn't be dragged, click to type and drag still moves it
            selectByMouse: false
            Keys.onEscapePressed: focus = false
            horizontalAlignment: w.d.align === "center" ? Text.AlignHCenter : w.d.align === "right" ? Text.AlignRight : Text.AlignLeft
            font.family: Theme.font
            font.pixelSize: 14 * w.s
            font.letterSpacing: 1
            color: w.ink
            onTextChanged: if (activeFocus) w.noteEdited(text)
        }
    }
}
