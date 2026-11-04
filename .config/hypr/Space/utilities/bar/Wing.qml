import QtQuick
import QtQuick.Shapes
import "../common"

Item {
    id: wing
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
    readonly property real panelW: Math.max(natW, kind === "media" ? 480 : 360)
    readonly property string live: dropped ? Ui.panel : ""
    property string kind: ""
    onLiveChanged: if (live !== "") { kind = live }
    property real extraW: dropped ? panelW - natW : 0
    property real drop: dropped ? body.height + 22 : 0
    Behavior on extraW { NumberAnimation { duration: Theme.open; easing.type: Easing.OutCubic } }
    Behavior on drop { NumberAnimation { duration: Theme.open; easing.type: Easing.OutCubic } }

    width: natW + extraW
    height: 28 + drop
    opacity: intro
    transform: Translate { y: -(1 - wing.intro) * 12 }
    SequentialAnimation on intro {
        PauseAnimation { duration: wing.introDelay }
        NumberAnimation { to: 1; duration: Theme.open; easing.type: Easing.OutCubic }
    }

    function fx(v) { return lean > 0 ? v : width - v }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: 1
            strokeColor: Theme.alpha(Theme.accent, 0.4)
            fillGradient: LinearGradient {
                y2: wing.height
                GradientStop { position: 0; color: Theme.alpha(Theme.bg, 0.72) }
                GradientStop { position: 1; color: Theme.alpha(Theme.bg, 0.42) }
            }
            startX: wing.fx(8); startY: 0
            PathLine { x: wing.fx(wing.width); y: 0 }
            PathLine { x: wing.fx(wing.width); y: wing.height - 8 }
            PathLine { x: wing.fx(wing.width - 8); y: wing.height }
            PathLine { x: wing.fx(0); y: wing.height }
            PathLine { x: wing.fx(0); y: 8 }
            PathLine { x: wing.fx(8); y: 0 }
        }
    }

    Bracket { x: wing.lean > 0 ? wing.width - 7 : 0; y: 0; atRight: wing.lean > 0; atBottom: false }
    Bracket { x: wing.lean > 0 ? 0 : wing.width - 7; y: wing.height - 7; atRight: wing.lean < 0; atBottom: true }

    Rectangle { x: 8; y: wing.height - 1; width: wing.width - 16; height: 1; color: Theme.alpha(Theme.accent, 0.28) }

    Row { id: inner; x: wing.padL + (wing.lean < 0 ? wing.extraW : 0); height: 28 }

    HoverHandler { id: hh }
    Timer { interval: 260; running: wing.dropped && !hh.hovered && !body.item?.holdOpen; onTriggered: Ui.panel = "" }

    Item {
        x: 0; y: 28
        width: wing.width
        height: Math.max(0, wing.height - 28)
        clip: true
        Rectangle { x: 12; y: 0; width: parent.width - 24; height: 1; color: Theme.alpha(Theme.accent, 0.25) }
        Loader {
            id: body
            x: 12
            y: 11 + Math.min(0, parent.height - height - 22)
            width: wing.panelW - 24
            opacity: wing.dropped ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.open; easing.type: Easing.OutCubic } }
            source: {
                switch (wing.kind) {
                case "net": return "../panels/PanelNet.qml"
                case "audio": return "../panels/PanelAudio.qml"
                case "power": return "../panels/PanelPower.qml"
                case "media": return "../panels/PanelMedia.qml"
                case "time": return "../panels/PanelTime.qml"
                case "tray": return "../panels/PanelTray.qml"
                case "updates": return "../panels/PanelUpdates.qml"
                case "notifs": return "../panels/PanelNotifs.qml"
                }
                return ""
            }
        }
    }
}
