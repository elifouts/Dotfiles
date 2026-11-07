import QtQuick
import "../../shared"
import "../common"

Item {
    id: pill

    property bool expanded: false
    property real fullWidth: 240
    property string hint: ""
    property string placeholder: "Search apps"
    property alias text: input.text
    readonly property alias input: input
    property var keyHandler: null
    signal clicked()

    property real open: 0
    onExpandedChanged: {
        morph.stop()
        morph.from = open
        morph.to = expanded ? 1 : 0
        morph.duration = Theme.ms(expanded ? 420 : 280)
        morph.easing.bezierCurve = expanded ? Theme.settle : Theme.leave
        morph.start()
    }
    NumberAnimation { id: morph; target: pill; property: "open"; easing.type: Easing.BezierSpline }

    readonly property real wobble: Math.sin(Math.max(0, Math.min(1, open)) * Math.PI)

    function stage(from) {
        return Math.max(0, Math.min(1, (open - from) / (1 - from)))
    }

    implicitHeight: 36
    width: height + (fullWidth - height) * open

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: parent.height
        radius: height / 2
        color: Theme.alpha(Theme.fg, (area.containsMouse && !pill.expanded ? 0.13 : 0.07) + 0.03 * pill.stage(0))
        border.width: 1
        border.color: Theme.alpha(Theme.accent, 0.55 * pill.stage(0.2))
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }

    LabelShared {
        x: (pill.height - width) / 2
        anchors.verticalCenter: parent.verticalCenter
        text: ""
        font.pixelSize: Math.round(pill.height * 0.4)
        rotation: -8 * pill.wobble
        scale: area.pressed ? 0.9 : 1
        color: pill.open > 0.5 ? Theme.accent : (area.containsMouse ? Theme.bright : Theme.fg)
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }

    Item {
        id: field
        anchors.left: parent.left
        anchors.leftMargin: pill.height - 4
        anchors.right: parent.right
        anchors.rightMargin: pill.height * 0.4
        height: parent.height
        clip: true
        opacity: pill.stage(0.35)

        TextInput {
            id: input
            anchors.left: parent.left
            anchors.right: hintText.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            font.family: Theme.sans
            font.pixelSize: 14
            color: Theme.bright
            selectionColor: Theme.alpha(Theme.accent, 0.5)
            selectedTextColor: Theme.bright
            clip: true
            cursorVisible: activeFocus && pill.expanded
            Keys.onPressed: event => { if (pill.keyHandler && pill.keyHandler(event)) event.accepted = true }
            transform: Translate { x: -14 * (1 - pill.stage(0.35)) }
        }

        Text {
            anchors.left: input.left
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === ""
            text: pill.placeholder
            font: input.font
            color: Theme.dim
            transform: Translate { x: -14 * (1 - pill.stage(0.35)) }
        }

        LabelShared {
            id: hintText
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, field.width * 0.45)
            elide: Text.ElideRight
            text: pill.hint !== "" ? "↵  " + pill.hint : ""
            font.pixelSize: 11
            color: Theme.dim
            opacity: pill.stage(0.6)
        }
    }

    HoverShared {
        id: area
        anchors.fill: parent
        enabled: !pill.expanded
        onClicked: pill.clicked()
    }
}
