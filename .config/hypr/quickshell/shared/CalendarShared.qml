import QtQuick
import Quickshell
import "../style/common"

Item {
    id: cal

    property bool open: false
    property bool typing: false
    readonly property bool holdOpen: open && typing
    function type(field) { typing = true; Qt.callLater(() => field.grab()) }
    function letGo() { typing = false; cal.forceActiveFocus() }

    implicitHeight: col.implicitHeight + 4
    readonly property bool wide: width >= 560
    readonly property bool ownHeight: true

    function key(d) { return TodosShared.key(d) }
    readonly property string todayKey: key(today)
    readonly property string pickedKey: key(picked)
    readonly property date today: new Date()
    property date month: new Date(today.getFullYear(), today.getMonth(), 1)
    property date picked: today
    property int slide: 1

    readonly property var todos: TodosShared.todos
    readonly property int done: TodosShared.done
    function tasks(d) { return TodosShared.tasks(d) }
    function put(d, list, finished) { TodosShared.put(d, list, finished) }

    function shift(n) {
        slide = n
        month = new Date(month.getFullYear(), month.getMonth() + n, 1)
        flip.restart()
    }

    property date target: today
    property int way: 1
    function pick(d, cell) {
        letGo()
        if (key(d) === key(target)) return
        way = d > target ? 1 : -1
        target = d
        const a = cell.mapToItem(cal, 0, 0), b = boxTitle.mapToItem(cal, 0, 0)
        ghost.text = String(d.getDate())
        ghost.from = Qt.point(a.x + (cell.width - ghost.width) / 2, a.y + (cell.height - ghost.height) / 2)
        ghost.to = Qt.point(b.x, b.y)
        morph.restart()
        turn.restart()
    }
    SequentialAnimation {
        id: turn
        ParallelAnimation {
            NumberAnimation { target: content; property: "opacity"; to: 0; duration: Theme.ms(120); easing.type: Easing.InQuad }
            NumberAnimation { target: content; property: "shift"; to: -cal.way * 14; duration: Theme.ms(120); easing.type: Easing.InQuad }
            NumberAnimation { target: boxTitle; property: "opacity"; to: 0; duration: Theme.ms(120) }
        }
        ScriptAction { script: { cal.picked = cal.target; list.refill(); content.shift = cal.way * 14; boxTitle.day = cal.target; boxTitle.typed = 0 } }
        PauseAnimation { duration: Theme.ms(150) }
        PropertyAction { target: boxTitle; property: "opacity"; value: 1 }
        ParallelAnimation {
            NumberAnimation { target: content; property: "opacity"; to: 1; duration: Theme.ms(220) }
            SettleShared { target: content; property: "shift"; to: 0; duration: Theme.move }
            NumberAnimation { target: boxTitle; property: "typed"; to: 1; duration: Theme.ms(Math.min(420, 120 + boxTitle.rest.length * 18)); easing.type: Easing.OutQuad }
        }
    }

    function reset() {
        letGo()
        turn.stop()
        morph.stop()
        ghost.p = 1
        content.opacity = 1
        content.shift = 0
        boxTitle.opacity = 1
        boxTitle.day = today
        boxTitle.typed = 1
        picked = target = today
        month = new Date(today.getFullYear(), today.getMonth(), 1)
        list.refill()
    }
    onOpenChanged: if (!open) reset()

    Item {
        id: col
        width: parent.width
        implicitHeight: cal.wide ? Math.max(monthCol.implicitHeight, box.height) : monthCol.implicitHeight + 10 + box.height

        Column {
            id: monthCol
            width: cal.wide ? 280 : parent.width
            spacing: 10

            Item {
                width: parent.width
                height: 24
                IconButtonShared {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: ""
                    font.pixelSize: 11
                    onClicked: cal.shift(-1)
                }
                SwapTextShared {
                    anchors.centerIn: parent
                    value: Qt.formatDate(cal.month, "MMMM yyyy")
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.bright
                }
                IconButtonShared {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: ""
                    font.pixelSize: 11
                    onClicked: cal.shift(1)
                }
            }

            Row {
                Repeater {
                    model: ["S", "M", "T", "W", "T", "F", "S"]
                    LabelShared {
                        required property string modelData
                        width: monthCol.width / 7
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        font.pixelSize: 10
                        color: Theme.dim
                    }
                }
            }

            Grid {
                id: grid
                columns: 7
                property real shift: 0
                transform: Translate { x: grid.shift }

                SequentialAnimation {
                    id: flip
                    PropertyAction { target: grid; property: "opacity"; value: 0 }
                    PropertyAction { target: grid; property: "shift"; value: cal.slide * 16 }
                    ParallelAnimation {
                        NumberAnimation { target: grid; property: "opacity"; to: 1; duration: Theme.ms(180) }
                        SettleShared { target: grid; property: "shift"; to: 0; duration: Theme.move }
                    }
                }

                Repeater {
                    model: 42
                    Item {
                        id: cell
                        required property int index
                        readonly property date day: new Date(cal.month.getFullYear(), cal.month.getMonth(), index - cal.month.getDay() + 1)
                        readonly property bool inMonth: day.getMonth() === cal.month.getMonth()
                        readonly property string k: cal.key(day)
                        readonly property bool isToday: k === cal.todayKey
                        readonly property bool isPicked: k === cal.pickedKey
                        readonly property int count: (cal.todos[k] ?? []).length
                        width: monthCol.width / 7
                        height: 30

                        Rectangle {
                            anchors.centerIn: parent
                            width: 26
                            height: 26
                            radius: 13 * Theme.round
                            readonly property real load: Math.min(1, 0.15 * cell.count)
                            color: cell.isPicked ? Theme.accent
                                : cell.count ? Theme.alpha(Theme.accent2, dayArea.containsMouse ? Math.min(1, load + 0.1) : load)
                                : Theme.alpha(Theme.fg, dayArea.containsMouse ? 0.1 : 0)
                            border.width: cell.isToday && !cell.isPicked ? 1 : 0
                            border.color: Theme.alpha(Theme.accent, 0.7)
                            scale: dayArea.pressed ? 0.88 : 1
                            Behavior on color { ColorAnimation { duration: Theme.fast } }
                            Behavior on scale { NumberAnimation { duration: Theme.ms(160); easing.type: Easing.OutBack; easing.overshoot: 2 } }
                        }
                        LabelShared {
                            anchors.centerIn: parent
                            text: cell.day.getDate()
                            font.pixelSize: 11
                            font.bold: cell.isToday
                            color: cell.isPicked ? Theme.ink : cell.count >= 4 ? Theme.on(Theme.accent2)
                                : cell.inMonth ? Theme.fg : Theme.alpha(Theme.dim, 0.5)
                            Behavior on color { ColorAnimation { duration: Theme.fast } }
                        }
                        HoverShared { id: dayArea; anchors.fill: parent; onClicked: cal.pick(cell.day, cell) }
                    }
                }
            }

        }

        Rectangle {
            id: box
            x: cal.wide ? monthCol.width + 16 : 0
            y: cal.wide ? 0 : monthCol.implicitHeight + 10
            width: cal.wide ? parent.width - monthCol.width - 16 : parent.width
            height: boxCol.implicitHeight + 20
            radius: Math.min(Theme.rounding, 12)
            color: Theme.alpha(Theme.fg, 0.05)

            Column {
                id: boxCol
                x: 10
                y: 10
                width: parent.width - 20

                Item {
                    width: parent.width
                    height: 18

                    LabelShared {
                        id: boxTitle
                        property date day: cal.today
                        property real typed: 1
                        readonly property string rest: "  " + (cal.key(day) === cal.todayKey ? "Today" : Qt.formatDate(day, "dddd, MMMM"))
                        anchors.verticalCenter: parent.verticalCenter
                        text: day.getDate() + rest.slice(0, Math.ceil(rest.length * typed))
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.bright
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        opacity: cal.done ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.move } }
                        LabelShared {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\uf00c"
                            font.pixelSize: 9
                            color: Theme.accent2
                        }
                        SwapTextShared {
                            anchors.verticalCenter: parent.verticalCenter
                            value: String(cal.done)
                            font.pixelSize: 11
                            color: Theme.dim
                        }
                    }
                }

                Item { width: 1; height: 6 }

                Item {
                    id: content
                    property real shift: 0
                    width: parent.width
                    height: list.height
                    clip: true
                    Behavior on height { SettleShared { duration: Theme.move } }
                    transform: Translate { x: content.shift }

                    ListView {
                        id: list
                        width: parent.width
                        height: contentHeight
                        interactive: false
                        spacing: 2
                        model: ListModel { id: rows }
                        readonly property real rowH: 28
                        property bool dragging: false
                        property bool quiet: false

                        function refill() {
                            quiet = true
                            rows.clear()
                            for (const t of cal.tasks(cal.picked)) rows.append({ task: t })
                            Qt.callLater(() => quiet = false)
                        }
                        function commit(finished) {
                            const out = []
                            for (let i = 0; i < rows.count; i++) out.push(rows.get(i).task)
                            cal.put(cal.picked, out, finished ?? 0)
                        }
                        Connections {
                            target: cal
                            function onTodosChanged() { if (!TodosShared.saving && !list.dragging && !turn.running) list.refill() }
                        }
                        Component.onCompleted: refill()

                        add: Transition {
                            enabled: !list.quiet
                            ParallelAnimation {
                                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.ms(200) }
                                SettleShared { property: "x"; from: -10; to: 0; duration: Theme.move }
                            }
                        }
                        remove: Transition {
                            enabled: !list.quiet
                            ParallelAnimation {
                                NumberAnimation { property: "opacity"; to: 0; duration: Theme.ms(160) }
                                NumberAnimation { property: "x"; to: 14; duration: Theme.ms(160); easing.type: Easing.InQuad }
                            }
                        }
                        displaced: Transition { enabled: !list.quiet; SettleShared { property: "y"; duration: Theme.move } }
                        move: Transition { SettleShared { property: "y"; duration: Theme.ms(160) } }

                        delegate: Item {
                            id: row
                            required property int index
                            required property string task
                            property bool editing: false
                            property bool checked: false
                            width: list.width
                            height: list.rowH

                            Rectangle {
                                anchors.fill: parent
                                radius: Math.min(Theme.rounding, 8)
                                color: Theme.alpha(Theme.fg, grab.pressed ? 0.12 : grab.containsMouse ? 0.07 : 0)
                                Behavior on color { ColorAnimation { duration: Theme.fast } }
                            }

                            Rectangle {
                                x: 7
                                opacity: row.editing ? 0 : 1
                                Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                                anchors.verticalCenter: parent.verticalCenter
                                width: 14
                                height: 14
                                radius: 7 * Theme.round
                                color: row.checked ? Theme.accent2 : "transparent"
                                border.width: 1.5
                                border.color: Theme.alpha(Theme.accent2, row.checked || tickArea.containsMouse ? 1 : 0.55)
                                scale: tickArea.pressed ? 0.82 : 1
                                Behavior on color { ColorAnimation { duration: Theme.fast } }
                                Behavior on border.color { ColorAnimation { duration: Theme.fast } }
                                Behavior on scale { NumberAnimation { duration: Theme.ms(200); easing.type: Easing.OutBack; easing.overshoot: 2.4 } }
                                LabelShared {
                                    anchors.centerIn: parent
                                    text: "\uf00c"
                                    font.pixelSize: 8
                                    color: Theme.on(Theme.accent2)
                                    opacity: row.checked ? 1 : 0
                                    scale: row.checked ? 1 : 0.3
                                    Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                                    Behavior on scale { NumberAnimation { duration: Theme.ms(260); easing.type: Easing.OutBack; easing.overshoot: 2.6 } }
                                }
                                HoverShared {
                                    id: tickArea
                                    anchors.fill: parent
                                    anchors.margins: -5
                                    enabled: !row.checked && !row.editing
                                    onClicked: { row.checked = true; finish.start() }
                                }
                            }
                            SequentialAnimation {
                                id: finish
                                PauseAnimation { duration: Theme.ms(340) }
                                ScriptAction { script: { rows.remove(row.index); list.commit(1) } }
                            }

                            LabelShared {
                                visible: !row.editing
                                x: 30
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 58
                                text: row.task
                                elide: Text.ElideRight
                                font.pixelSize: 12
                                font.strikeout: row.checked
                                color: Theme.fg
                                opacity: row.checked ? 0.45 : 1
                                Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                            }

                            MouseArea {
                                id: grab
                                anchors.fill: parent
                                anchors.leftMargin: 26
                                anchors.rightMargin: 26
                                enabled: !row.editing && !row.checked
                                hoverEnabled: true
                                cursorShape: list.dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                property real startY: 0
                                property bool moved: false
                                onPressed: mouse => { startY = mouse.y; moved = false }
                                onPositionChanged: mouse => {
                                    if (!pressed) return
                                    if (!moved && Math.abs(mouse.y - startY) < 4) return
                                    moved = true
                                    list.dragging = true
                                    const y = mapToItem(list.contentItem, 0, mouse.y).y
                                    const to = Math.max(0, Math.min(rows.count - 1, Math.floor(y / (list.rowH + list.spacing))))
                                    if (to !== row.index) rows.move(row.index, to, 1)
                                }
                                onReleased: {
                                    if (moved) { list.dragging = false; list.commit() }
                                    else { row.editing = true; cal.type(rename) }
                                }
                            }

                            Field {
                                id: rename
                                visible: row.editing
                                anchors.verticalCenter: parent.verticalCenter
                                height: 26
                                text: row.task
                                onAccepted: {
                                    if (text.trim() === "") rows.remove(row.index)
                                    else rows.setProperty(row.index, "task", text.trim())
                                    row.editing = false
                                    cal.letGo()
                                    list.commit()
                                }
                                Keys.onEscapePressed: { row.editing = false; cal.letGo() }
                            }

                            IconButtonShared {
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !row.editing && !row.checked
                                opacity: grab.containsMouse || hovered ? 1 : 0
                                text: "\uf00d"
                                font.pixelSize: 10
                                hot: Theme.warn
                                Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                                onClicked: { rows.remove(row.index); list.commit() }
                            }
                        }
                    }
                }

                Item { width: 1; height: 6 }

                Field {
                    id: add
                    height: 28
                    placeholder: "Add something"
                    onAccepted: {
                        const t = text.trim()
                        if (t !== "") { rows.append({ task: t }); list.commit() }
                        text = ""
                    }
                    Keys.onEscapePressed: { text = ""; cal.letGo() }
                    MouseArea {
                        anchors.fill: parent
                        visible: !add.activeFocus && !cal.typing
                        cursorShape: Qt.IBeamCursor
                        onClicked: cal.type(add)
                    }
                }
            }
        }
    }

    LabelShared {
        id: ghost
        property point from
        property point to
        property real p: 1
        visible: p < 1
        x: from.x + (to.x - from.x) * p
        y: from.y + (to.y - from.y) * p
        font.pixelSize: 11 + 1 * p
        font.bold: true
        color: Theme.bright
        scale: 1 + 0.35 * Math.sin(Math.PI * p)
    }
    NumberAnimation {
        id: morph
        target: ghost; property: "p"; from: 0; to: 1
        duration: Theme.ms(270); easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.settle
    }
}
