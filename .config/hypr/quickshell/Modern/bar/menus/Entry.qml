import QtQuick
import Quickshell.Widgets
import "../../../shared"
import "../../common"

Rectangle {
    id: row

    property string glyph: ""
    property string iconSource: ""
    property string label: ""
    property string sub: ""
    property string trailing: ""
    property bool active: false
    property bool busy: false
    property bool enabledRow: true
    property bool gear: false
    readonly property bool hot: area.containsMouse || cogArea.containsMouse
    signal clicked()
    signal rightClicked()
    signal settingsClicked()

    property real triedAt: 0
    function cheer() {
        triedAt = 0
        wiggle.stop()
        settle.stop()
        party.restart()
    }
    onBusyChanged: {
        triedAt = Date.now()
        if (busy) { party.stop(); settle.stop(); wiggle.restart(); return }
        wiggle.stop()
        if (active) cheer()
        else settle.restart()
    }
    onActiveChanged: if (active && !busy && Date.now() - triedAt < 2500) cheer()
    Component.onCompleted: if (busy) { triedAt = Date.now(); wiggle.start() }

    width: parent ? parent.width : 0
    height: sub !== "" ? 46 : 36
    color: active ? Theme.soft(Theme.accent, area.containsMouse)
        : Theme.alpha(Theme.fg, area.containsMouse && enabledRow ? 0.1 : 0)
    opacity: enabledRow ? 1 : 0.45
    Behavior on color { ColorAnimation { duration: Theme.ms(120) } }

    Item {
        id: lead
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        width: 20
        height: 20
        visible: row.glyph !== "" || row.iconSource !== ""

        LabelShared {
            anchors.centerIn: parent
            visible: row.iconSource === ""
            text: row.glyph
            font.pixelSize: 15
            color: row.active ? Theme.ink : row.busy ? Theme.accent : Theme.fg
            Behavior on color { ColorAnimation { duration: Theme.ms(200) } }
        }

        IconImage {
            anchors.centerIn: parent
            visible: row.iconSource !== ""
            implicitSize: 18
            source: row.iconSource
        }
    }

    SequentialAnimation {
        id: wiggle
        loops: Animation.Infinite
        NumberAnimation { target: lead; property: "rotation"; to: -16; duration: 200; easing.type: Easing.InOutSine }
        NumberAnimation { target: lead; property: "rotation"; to: 14; duration: 320; easing.type: Easing.InOutSine }
        NumberAnimation { target: lead; property: "rotation"; to: -9; duration: 280; easing.type: Easing.InOutSine }
        NumberAnimation { target: lead; property: "rotation"; to: 0; duration: 220; easing.type: Easing.InOutSine }
        NumberAnimation { target: lead; property: "scale"; to: 1.2; duration: 240; easing.type: Easing.InOutSine }
        NumberAnimation { target: lead; property: "scale"; to: 1; duration: 360; easing.type: Easing.InOutSine }
        PauseAnimation { duration: 100 }
    }

    ParallelAnimation {
        id: settle
        NumberAnimation { target: lead; property: "rotation"; to: 0; duration: Theme.ms(300); easing.type: Easing.OutCubic }
        NumberAnimation { target: lead; property: "scale"; to: 1; duration: Theme.ms(300); easing.type: Easing.OutCubic }
    }

    SequentialAnimation {
        id: party
        ParallelAnimation {
            NumberAnimation { target: lead; property: "rotation"; to: 360; duration: Theme.ms(760); easing.type: Easing.OutBack; easing.overshoot: 1.4 }
            SequentialAnimation {
                NumberAnimation { target: lead; property: "scale"; to: 1.4; duration: Theme.ms(260); easing.type: Easing.OutQuad }
                NumberAnimation { target: lead; property: "scale"; to: 1; duration: Theme.ms(500); easing.type: Easing.OutBack; easing.overshoot: 2.2 }
            }
        }
        PropertyAction { target: lead; property: "rotation"; value: 0 }
    }

    Column {
        anchors.left: lead.visible ? lead.right : parent.left
        anchors.leftMargin: lead.visible ? 10 : 16
        anchors.right: cog.visible ? cog.left : tail.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        LabelShared {
            width: parent.width
            text: row.label
            elide: Text.ElideRight
            font.pixelSize: 13
            color: row.active ? Theme.ink : row.hot ? Theme.bright : Theme.fg
        }
        LabelShared {
            width: parent.width
            visible: row.sub !== ""
            text: row.sub
            elide: Text.ElideRight
            font.pixelSize: 10
            color: row.active ? Theme.alpha(Theme.ink, 0.7) : Theme.dim
        }
    }

    LabelShared {
        id: tail
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        text: row.trailing
        font.pixelSize: 11
        color: row.active ? Theme.ink : Theme.dim
    }

    HoverShared {
        id: area
        anchors.fill: parent
        enabled: row.enabledRow
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => m.button === Qt.RightButton ? row.rightClicked() : row.clicked()
    }

    Item {
        id: cog
        visible: row.gear
        anchors.right: tail.left
        anchors.rightMargin: tail.text !== "" ? 4 : -4
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: row.hot ? 26 : 0
        Behavior on width { NumberAnimation { duration: Theme.ms(180); easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 24
            height: 24
            radius: Math.min(Theme.rounding, height / 2)
            color: Theme.alpha(Theme.fg, cogArea.containsMouse ? 0.14 : 0)
            opacity: row.hot ? 1 : 0
            scale: row.hot ? 1 : 0.6
            Behavior on color { ColorAnimation { duration: Theme.ms(120) } }
            Behavior on opacity { NumberAnimation { duration: Theme.ms(160) } }
            Behavior on scale { NumberAnimation { duration: Theme.ms(180); easing.type: Easing.OutBack } }

            LabelShared {
                anchors.centerIn: parent
                text: "\uf013"
                font.pixelSize: 12
                color: row.active ? Theme.ink : cogArea.containsMouse ? Theme.bright : Theme.dim
            }

            HoverShared {
                id: cogArea
                anchors.fill: parent
                anchors.margins: -2
                enabled: row.gear
                onClicked: row.settingsClicked()
            }
        }
    }
}
