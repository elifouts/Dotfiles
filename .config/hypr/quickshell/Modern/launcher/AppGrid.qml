import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../shared"
import "../common"

Flickable {
    id: grid

    property var apps: []
    property var slots: ({})
    property int count: 0
    property int selected: 0
    property int cols: 4
    property real cell: 68
    property real gap: 14
    property real hlPad: 5
    property string emptyText: ""
    property bool mouseMoved: false
    property real intro: 1
    signal launch(var app)
    signal hover(int slot)

    readonly property real pitch: cell + gap
    readonly property real inset: Math.max(hlPad + 4, Math.round(gap * 0.4))
    readonly property real side: Math.round((width - (cols * cell + (cols - 1) * gap)) / 2)
    readonly property int rows: Math.ceil(count / cols)

    function slotX(s) { return side + (s % cols) * pitch }
    function slotY(s) { return inset + Math.floor(s / cols) * pitch }

    clip: true
    contentWidth: width
    contentHeight: Math.max(height, inset * 2 + rows * pitch - gap)
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.VerticalFlick

    function scrollTo(y) {
        scrollAnim.stop()
        scrollAnim.from = contentY
        scrollAnim.to = Math.max(0, Math.min(contentHeight - height, y))
        scrollAnim.start()
    }

    function reveal(s) {
        if (s < 0) return
        const top = slotY(s) - inset
        const bottom = slotY(s) + cell + inset
        const target = scrollAnim.running ? scrollAnim.to : contentY
        if (top < target) scrollTo(top)
        else if (bottom > target + height) scrollTo(bottom - height)
    }

    NumberAnimation { id: scrollAnim; target: grid; property: "contentY"; duration: Theme.ms(260); easing.type: Easing.OutCubic }

    onSelectedChanged: reveal(selected)

    HoverHandler {
        onPointChanged: grid.mouseMoved = true
    }

    MouseArea {
        width: grid.contentWidth
        height: grid.contentHeight
        acceptedButtons: Qt.NoButton
        onWheel: event => {
            if (event.pixelDelta.y !== 0) {
                scrollAnim.stop()
                grid.contentY = Math.max(0, Math.min(grid.contentHeight - grid.height, grid.contentY - event.pixelDelta.y))
            } else {
                const base = scrollAnim.running ? scrollAnim.to : grid.contentY
                grid.scrollTo(base - event.angleDelta.y / 120 * grid.pitch)
            }
        }
    }

    Rectangle {
        x: grid.slotX(grid.selected) - grid.hlPad
        y: grid.slotY(grid.selected) - grid.hlPad
        width: grid.cell + grid.hlPad * 2
        height: width
        radius: Theme.r(10) + grid.hlPad
        color: Theme.alpha(Theme.accent, 0.26)
        border.width: 1
        border.color: Theme.alpha(Theme.accent, 0.55)
        opacity: grid.count > 0 ? 1 : 0
        Behavior on x { NumberAnimation { duration: Theme.ms(200); easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: Theme.ms(200); easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: Theme.fast } }
    }

    Repeater {
        model: grid.apps

        Item {
            id: tile
            required property var modelData
            readonly property int slot: grid.slots[modelData.id] ?? -1
            readonly property real layoutKey: grid.side + grid.cell * 1000
            readonly property string src: Quickshell.iconPath(modelData.icon, true)
                || Quickshell.iconPath("application-x-executable", true)

            property real present: slot >= 0 ? 1 : 0
            Behavior on present { NumberAnimation { duration: Theme.ms(tile.slot >= 0 ? 300 : 200); easing.type: Easing.OutCubic } }

            readonly property real rise: {
                const row = Math.min(6, Math.floor(Math.max(0, slot) / grid.cols))
                const e = Math.max(0, Math.min(1, (grid.intro - row * 0.07) / 0.58))
                return 1 - Math.pow(1 - e, 3)
            }

            width: grid.cell
            height: grid.cell
            visible: opacity > 0.01
            opacity: present * rise
            scale: 0.92 + 0.08 * present
            transform: Translate { y: 10 * (1 - tile.rise) }

            Behavior on x { id: moveX; SettleShared { duration: Theme.ms(420) } }
            Behavior on y { id: moveY; SettleShared { duration: Theme.ms(420) } }

            function jumpTo(nx, ny) {
                moveX.enabled = false
                moveY.enabled = false
                x = nx
                y = ny
                moveX.enabled = true
                moveY.enabled = true
            }

            function place(instant) {
                if (slot < 0) return
                if (instant || present < 0.2) jumpTo(grid.slotX(slot), grid.slotY(slot))
                else { x = grid.slotX(slot); y = grid.slotY(slot) }
            }
            Component.onCompleted: place(true)
            onSlotChanged: place(false)
            onLayoutKeyChanged: place(true)

            IconImage {
                id: icon
                anchors.centerIn: parent
                implicitSize: Math.round(grid.cell * 0.74)
                source: tile.src
                asynchronous: true
                mipmap: true
                visible: tile.src !== "" && status !== Image.Error
                scale: hit.containsMouse ? 1.06 : 1
                Behavior on scale { NumberAnimation { duration: Theme.ms(220); easing.type: Easing.OutCubic } }
            }

            LabelShared {
                anchors.centerIn: parent
                visible: !icon.visible
                text: tile.modelData.name.charAt(0).toUpperCase()
                font.pixelSize: Math.round(grid.cell * 0.46)
                color: Theme.accent
            }

            HoverShared {
                id: hit
                anchors.fill: parent
                enabled: tile.slot >= 0
                onEntered: if (grid.mouseMoved) grid.hover(tile.slot)
                onPositionChanged: if (grid.mouseMoved && grid.selected !== tile.slot) grid.hover(tile.slot)
                onClicked: grid.launch(tile.modelData)
            }
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: grid.height * 0.32
        spacing: 8
        opacity: grid.count === 0 ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: Theme.ms(240) } }

        LabelShared {
            anchors.horizontalCenter: parent.horizontalCenter
            text: ""
            font.pixelSize: 26
            color: Theme.alpha(Theme.fg, 0.25)
        }
        LabelShared {
            anchors.horizontalCenter: parent.horizontalCenter
            width: grid.width - 40
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideMiddle
            text: grid.emptyText
            font.pixelSize: 13
            color: Theme.dim
        }
    }
}
