import QtQuick
import QtQuick.Shapes
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
    readonly property real panelW: Math.max(natW, ({ media: 480, net: 672, audio: 672 })[kind] ?? 360)
    readonly property string live: dropped ? Ui.panel : ""
    property string kind: ""
    onLiveChanged: if (live !== "") { kind = live }
    property real extraW: dropped ? panelW - natW : 0
    property real drop: dropped ? body.height + 22 : 0
    Behavior on extraW { SettleShared { duration: Theme.open } }
    Behavior on drop { SettleShared { duration: Theme.open } }

    width: natW + extraW
    height: 28 + drop
    opacity: intro
    transform: Translate { y: -(1 - pill.intro) * 12 }
    SequentialAnimation on intro {
        PauseAnimation { duration: pill.introDelay }
        SettleShared { to: 1; duration: Theme.open }
    }

    function fx(v) { return lean > 0 ? v : width - v }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: 1
            strokeColor: Theme.alpha(Theme.accent, 0.4)
            fillGradient: LinearGradient {
                y2: pill.height
                GradientStop { position: 0; color: Theme.alpha(Theme.bg, 0.72) }
                GradientStop { position: 1; color: Theme.alpha(Theme.bg, 0.42) }
            }
            startX: pill.fx(8); startY: 0
            PathLine { x: pill.fx(pill.width); y: 0 }
            PathLine { x: pill.fx(pill.width); y: pill.height - 8 }
            PathLine { x: pill.fx(pill.width - 8); y: pill.height }
            PathLine { x: pill.fx(0); y: pill.height }
            PathLine { x: pill.fx(0); y: 8 }
            PathLine { x: pill.fx(8); y: 0 }
        }
    }

    Bracket { x: pill.lean > 0 ? pill.width - 7 : 0; y: 0; atRight: pill.lean > 0; atBottom: false }
    Bracket { x: pill.lean > 0 ? 0 : pill.width - 7; y: pill.height - 7; atRight: pill.lean < 0; atBottom: true }

    Rectangle { x: 8; y: pill.height - 1; width: pill.width - 16; height: 1; color: Theme.alpha(Theme.accent, 0.28) }

    Row { id: inner; x: pill.padL + (pill.lean < 0 ? pill.extraW : 0); height: 28 }

    HoverHandler { id: hh }
    Connections {
        target: body.item
        ignoreUnknownSignals: true
        function onRun(cmd) { HyprShared.run(cmd) }
        function onDone() { Ui.panel = "" }
    }
    Timer { interval: 260; running: pill.dropped && !hh.hovered && !body.item?.holdOpen; onTriggered: Ui.panel = "" }

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
            Behavior on opacity { SettleShared { duration: Theme.open } }
            source: pill.kind ? "menus/" + ({ audio: "SoundShared", media: "Island", net: "NetworkShared", notifs: "NotificationsShared", power: "Session", time: "Calendar", tray: "Tray", updates: "UpdateMenuShared" })[pill.kind] + ".qml" : ""
            onLoaded: if ("open" in item) item.open = Qt.binding(() => pill.dropped)
        }
    }
}
