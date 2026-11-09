import QtQuick
import "../../shared"
import "../common"

Item {
    id: pill

    component Bracket: Item {
        property bool atRight: false
        property bool atBottom: false
        width: 7; height: 7
        Rectangle { width: 7; height: 1; y: parent.atBottom ? 6 : 0; color: Theme.accent; opacity: 0.9 }
        Rectangle { width: 1; height: 7; x: parent.atRight ? 6 : 0; color: Theme.accent; opacity: 0.9 }
    }
    property int lean: 1
    property bool attached: false
    property real padL: 14
    property real padR: 14
    property real introDelay: 0
    property real intro: 0
    property var scr: null
    property bool active: true
    property int openCount: 0
    readonly property bool dropped: openCount > 0
    default property alias content: inner.data

    readonly property real natW: inner.implicitWidth + padL + padR
    readonly property real panelW: Math.max(natW, ({ media: 480, net: 420, audio: 420 })[kind] ?? 360)
    readonly property string live: dropped ? Ui.panel : ""
    property string kind: ""
    onLiveChanged: if (live !== "") { kind = live }
    property real extraW: dropped ? panelW - natW : 0
    property real drop: dropped ? body.height + 22 : 0
    readonly property int speed: dropped ? Theme.open : Theme.fast
    Behavior on extraW { SettleShared { duration: pill.speed } }
    Behavior on drop { SettleShared { duration: pill.speed } }

    width: natW + extraW
    height: 28 + drop
    opacity: intro
    transform: Translate { y: -(1 - pill.intro) * 12 }
    SequentialAnimation on intro {
        PauseAnimation { duration: pill.introDelay }
        SettleShared { to: 1; duration: Theme.open }
    }

    Rectangle {
        y: pill.attached ? -1 : 0
        width: pill.width
        height: pill.height - y
        border.width: 1
        border.color: Theme.alpha(Theme.accent, 0.4)
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.back(0.72) }
            GradientStop { position: 1; color: Theme.back(0.42) }
        }
    }

    Repeater {
        model: 4
        Bracket {
            required property int index
            atRight: index % 2 === 1
            atBottom: index > 1
            visible: atBottom || !pill.attached
            x: atRight ? pill.width - 7 : 0
            y: atBottom ? pill.height - 7 : 0
        }
    }

    Row { id: inner; x: pill.padL + (pill.lean < 0 ? pill.extraW : pill.lean === 0 ? pill.extraW / 2 : 0); height: 28; spacing: 14 }

    HoverHandler { id: hh }
    Connections {
        target: body.item
        ignoreUnknownSignals: true
        function onRun(cmd) { HyprShared.run(cmd) }
        function onDone() { Ui.panel = "" }
    }
    Timer { interval: 90; running: pill.dropped && !hh.hovered && !body.item?.holdOpen; onTriggered: Ui.panel = "" }

    Item {
        x: 0; y: 28
        width: pill.width
        height: Math.max(0, pill.height - 28)
        clip: true
        Rectangle { x: 12; y: 0; width: parent.width - 24; height: 1; color: Theme.alpha(Theme.accent, 0.25) }
        Loader {
            id: body
            x: 12
            y: 11 + Math.min(0, parent.height - height - 22)
            width: pill.panelW - 24
            opacity: pill.dropped ? 1 : 0
            Behavior on opacity { SettleShared { duration: pill.speed } }
            source: pill.kind ? ({ audio: "../../shared/SoundShared", media: "menus/Island", net: "../../shared/NetworkShared", notifs: "../../shared/NotificationsShared", power: "menus/Session", time: "menus/Calendar", tray: "menus/Tray", updates: "../../shared/UpdateMenuShared" })[pill.kind] + ".qml" : ""
            onLoaded: if ("open" in item) item.open = Qt.binding(() => pill.dropped)
        }
    }
}
