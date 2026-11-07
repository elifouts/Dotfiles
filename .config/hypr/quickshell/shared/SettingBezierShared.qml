import QtQuick
import Quickshell
import "../style/common"
import "MotionShared.js" as Motion

Item {
    id: control

    readonly property var curve: StoreShared.values["animation.curve"] || Motion.CURVE
    readonly property real speed: StoreShared.values["animation.speed"] || 1
    readonly property string windowStyle: StoreShared.values["animation.window"] || "popin 90%"
    readonly property int realMs: Math.round(400 / speed)
    readonly property int previewMs: Math.max(600, realMs)
    readonly property bool custom: StoreShared.values["animation.preset"] !== "theme"

    property real t: 0
    property real p: 0

    readonly property string nums: curve.map(v => Number(v).toFixed(2)).join(", ")
    readonly property string css: "cubic-bezier(" + nums + ")"
    readonly property string hyprLine: "bezier = custom, " + nums
    readonly property var spline: curve.slice(0, 4).concat([1, 1])

    function edit(c) {
        StoreShared.setMany({ "animation.preset": "custom", "animation.curve": c })
    }

    function commitText(index, raw) {
        const nums = raw.split(/[\s,;()]+/).map(parseFloat).filter(n => !isNaN(n))
        const c = control.curve.slice()
        if (nums.length >= 4) {
            for (let i = 0; i < 4; i++) c[i] = nums[i]
        } else if (nums.length >= 1) {
            c[index] = nums[0]
        } else {
            return
        }
        for (let i = 0; i < 4; i++) {
            const lo = i % 2 === 0 ? 0 : -0.5
            const hi = i % 2 === 0 ? 1 : 1.5
            c[i] = Math.round(Math.max(lo, Math.min(hi, c[i])) * 100) / 100
        }
        control.edit(c)
    }

    function rand(lo, hi, step) {
        const v = lo + Math.random() * (hi - lo)
        return Math.round(v / step) * step
    }

    function pickOf(list) { return list[Math.floor(Math.random() * list.length)].v }

    function randomize() {
        const r = (lo, hi) => Number(rand(lo, hi, 0.01).toFixed(2))
        edit([r(0.05, 0.8), r(-0.3, 1.2), r(0.2, 0.95), r(0.6, 1.45)])
        StoreShared.setMany({
            "animation.speed": Number(rand(0.6, 1.9, 0.05).toFixed(2)),
            "animation.window": pickOf(Motion.WINDOWS),
            "animation.workspace": pickOf(Motion.WORKSPACES)
        })
    }

    implicitHeight: body.height + 18

    Timer { id: restart; interval: 140; onTriggered: loop.restart() }
    onCurveChanged: restart.restart()
    onPreviewMsChanged: restart.restart()

    SequentialAnimation {
        id: loop
        running: control.visible
        loops: Animation.Infinite

        PropertyAction { target: control; property: "p"; value: 0 }
        PropertyAction { target: control; property: "t"; value: 0 }
        PauseAnimation { duration: 320 }

        ParallelAnimation {
            NumberAnimation { target: control; property: "t"; from: 0; to: 1; duration: control.previewMs }
            NumberAnimation {
                target: control
                property: "p"
                from: 0
                to: 1
                duration: control.previewMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: control.spline
            }
        }
        PauseAnimation { duration: 700 }
        ParallelAnimation {
            NumberAnimation { target: control; property: "t"; from: 1; to: 0; duration: control.previewMs }
            NumberAnimation {
                target: control
                property: "p"
                from: 1
                to: 0
                duration: control.previewMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: control.spline
            }
        }
        PauseAnimation { duration: 500 }
    }

    Column {
        id: body
        y: 12
        x: Theme.pad
        width: parent.width - Theme.pad * 2
        spacing: 12

        Row {
            width: parent.width
            spacing: 14

            CurvePlotShared {
                id: plot
                width: Math.min(236, Math.round(body.width * 0.5))
                height: width
                curve: control.curve
                t: control.t
                p: control.p
                playing: loop.running
                onEdited: c => control.edit(c)
                onResetRequested: StoreShared.reset("animation")
            }

            Column {
                width: body.width - plot.width - 14
                spacing: 10

                Rectangle {
                    id: stage
                    width: parent.width
                    height: plot.height - 74
                    radius: Theme.r(12)
                    color: Theme.alpha(Theme.fg, 0.045)
                    border.width: Theme.lines
                    border.color: Theme.edge
                    clip: true

                    Rectangle {
                        readonly property real prog: control.p
                        readonly property string style: control.windowStyle
                        readonly property real startScale: style.indexOf("popin") === 0 ? (parseFloat(style.split(" ")[1]) || 90) / 100 : 1

                        width: Math.min(130, stage.width * 0.7)
                        height: stage.height * 0.58
                        radius: Theme.r(9)
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: (stage.height - height) / 2 + (style === "slide" ? (1 - prog) * stage.height * 0.7 : 0)
                        scale: style === "slide" ? 1 : (style === "gnomed" ? Math.max(0, 0.5 + 0.5 * prog) : startScale + (1 - startScale) * prog)
                        transformOrigin: style === "gnomed" ? Item.Bottom : Item.Center
                        opacity: Math.max(0, Math.min(1, prog * 2.2))
                        color: Theme.alpha(Theme.accent, 0.4)
                        border.width: 1
                        border.color: Theme.alpha(Theme.bright, 0.35)

                        Row {
                            x: 10
                            y: 9
                            spacing: 4
                            Repeater { model: 3; Rectangle { width: 6; height: 6; radius: 3 * Theme.round; color: Theme.alpha(Theme.bright, 0.5) } }
                        }
                        Rectangle { x: 10; y: 28; width: parent.width - 20; height: 4; radius: 2; color: Theme.alpha(Theme.bright, 0.25) }
                        Rectangle { x: 10; y: 38; width: (parent.width - 20) * 0.6; height: 4; radius: 2; color: Theme.alpha(Theme.bright, 0.18) }
                    }
                }

                Item {
                    width: parent.width
                    height: 90

                    Text { x: 6; y: 2; text: "linear"; font.family: Theme.sans; font.pixelSize: 12; font.capitalization: Theme.caps; font.letterSpacing: Theme.tracking;  color: Theme.dim }
                    Rectangle { x: 6; y: 26; width: parent.width - 12; height: 2; radius: 1; color: Theme.alpha(Theme.fg, 0.14) }
                    Rectangle {
                        x: 6 + (parent.width - 12) * control.t - 5; y: 22; width: 10; height: 10; radius: 5 * Theme.round
                        color: Theme.alpha(Theme.fg, 0.5)
                    }

                    Text { x: 6; y: 48; text: "this curve"; font.family: Theme.sans; font.pixelSize: 12; font.capitalization: Theme.caps; font.letterSpacing: Theme.tracking;  color: Theme.dim }
                    Rectangle { x: 6; y: 72; width: parent.width - 12; height: 2; radius: 1; color: Theme.alpha(Theme.fg, 0.14) }
                    Rectangle {
                        x: 6 + (parent.width - 12) * control.p - 6; y: 67; width: 12; height: 12; radius: 6 * Theme.round
                        color: Theme.accent
                    }
                }
            }
        }

        Row {
            id: fields
            width: parent.width
            spacing: 8

            Repeater {
                model: ["x1", "y1", "x2", "y2"]

                Rectangle {
                    id: field
                    required property string modelData
                    required property int index
                    readonly property string val: Number(control.curve[index]).toFixed(2)
                    width: (fields.width - fields.spacing * 3) / 4
                    height: 32
                    radius: Theme.r(9)
                    color: Theme.alpha(Theme.fg, input.activeFocus ? 0.14 : 0.07)
                    border.width: input.activeFocus ? 1 : Theme.lines
                    border.color: input.activeFocus ? Theme.alpha(Theme.accent, 0.8) : Theme.edge
                    Behavior on color { ColorAnimation { duration: Theme.fast } }

                    LabelShared {
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: field.modelData
                        font.pixelSize: 10
                        font.capitalization: Theme.caps
                        font.letterSpacing: Theme.tracking
                        color: Theme.dim
                    }

                    TextInput {
                        id: input
                        anchors.fill: parent
                        anchors.leftMargin: 30
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        horizontalAlignment: TextInput.AlignRight
                        selectByMouse: true
                        clip: true
                        font.family: Theme.sans
                        font.pixelSize: 12
                        color: Theme.bright
                        selectionColor: Theme.alpha(Theme.accent, 0.5)
                        text: field.val
                        function rebind() { text = Qt.binding(() => field.val); control.forceActiveFocus() }
                        onActiveFocusChanged: if (activeFocus) selectAll()
                        onEditingFinished: {
                            control.commitText(field.index, text)
                            rebind()
                        }
                        Keys.onEscapePressed: event => {
                            rebind()
                            event.accepted = true
                        }
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: 34

            LabelShared {
                anchors.left: parent.left
                anchors.right: dice.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.WordWrap
                text: control.css + "\n" + (control.custom ? "opens windows in ~" + control.realMs + " ms" : "")
                font.pixelSize: 11
                color: Theme.fg
            }

            Button {
                id: dice
                anchors.right: copy.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                primary: true
                label: "\uf074   Randomize"
                onPressed: control.randomize()
            }

            Button {
                id: copy
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                label: "Copy line"
                Timer { id: copied; interval: 1200; onTriggered: copy.label = "Copy line" }
                onPressed: {
                    Quickshell.execDetached(["wl-copy", control.hyprLine])
                    label = "Copied"
                    copied.restart()
                }
            }
        }
    }
}
