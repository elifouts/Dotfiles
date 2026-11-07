import QtQuick
import "../../shared"
import "../common"

Item {
    id: control

    property var def
    readonly property var raw: StoreShared.values[def.key]
    readonly property bool ready: raw !== undefined && raw !== null
    readonly property string hex: ready ? (Number(raw) >>> 0).toString(16).padStart(8, "0") : "ffffff00"
    readonly property string alphaHex: hex.slice(6)
    readonly property var palette: Theme.wal
        ? [1, 2, 3, 4, 5, 6, 9, 15].map(i => Theme.wal.colors["color" + i])
        : []

    implicitHeight: 84
    opacity: ready ? 1 : 0.35
    enabled: ready

    function commit(rgb, alpha) {
        StoreShared.set(def.key, parseInt(rgb + alpha, 16))
    }

    function commitText(text) {
        const m = text.trim().replace(/^(#|0x)/i, "").match(/^([0-9a-f]{6})([0-9a-f]{2})?$/i)
        if (m) commit(m[1].toLowerCase(), (m[2] || alphaHex).toLowerCase())
    }

    LabelShared {
        x: Theme.pad
        y: 12
        text: control.def.label
        font.pixelSize: 13
        color: Theme.fg
    }

    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: Theme.pad
        y: 6
        width: 118
        height: 28
        radius: Math.min(Theme.rounding, 9)
        color: Theme.alpha(Theme.fg, input.activeFocus ? 0.14 : 0.07)
        border.width: input.activeFocus ? 1 : 0
        border.color: Theme.alpha(Theme.accent, 0.8)

        Rectangle {
            x: 6
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            radius: Math.min(Theme.rounding, 5)
            border.width: 1
            border.color: Theme.alpha(Theme.fg, 0.3)
            color: "#" + control.alphaHex + control.hex.slice(0, 6)
        }

        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: 28
            anchors.rightMargin: 8
            verticalAlignment: TextInput.AlignVCenter
            horizontalAlignment: TextInput.AlignRight
            selectByMouse: true
            clip: true
            font.family: Theme.sans
            font.pixelSize: 12
            color: Theme.bright
            selectionColor: Theme.alpha(Theme.accent, 0.5)
            text: "#" + control.hex
            onActiveFocusChanged: if (activeFocus) selectAll()
            onEditingFinished: {
                control.commitText(text)
                text = Qt.binding(() => "#" + control.hex)
                control.forceActiveFocus()
            }
            Keys.onEscapePressed: event => {
                text = Qt.binding(() => "#" + control.hex)
                control.forceActiveFocus()
                event.accepted = true
            }
        }
    }

    Row {
        x: Theme.pad
        y: 48
        spacing: 8

        Repeater {
            model: control.palette.concat(["#ffffff", "#000000"])

            Rectangle {
                id: chip
                required property var modelData
                readonly property bool current: String(modelData).slice(1).toLowerCase() === control.hex.slice(0, 6)
                width: 22
                height: 22
                radius: 11
                color: modelData
                border.width: current ? 2 : 1
                border.color: current ? Theme.accent : Theme.alpha(Theme.fg, 0.25)
                scale: chipArea.containsMouse ? 1.15 : 1
                Behavior on scale { NumberAnimation { duration: Theme.fast } }

                HoverShared {
                    id: chipArea
                    anchors.fill: parent
                    onClicked: control.commit(String(chip.modelData).slice(1).toLowerCase(),
                                              control.alphaHex === "00" ? "33" : control.alphaHex)
                }
            }
        }
    }

    ResetArea { z: -1; key: control.def.key }
}
