import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../style/common"

PanelWindow {
    id: win

    property bool hidden: false
    readonly property var focusScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    readonly property real u: focusScreen ? Math.max(0.6, Math.min(1.6, Math.min(focusScreen.width, focusScreen.height) / 900)) : 1
    readonly property int wanted: NotifsShared.popups.length
    property bool alive: false

    onWantedChanged: {
        if (wanted > 0) {
            linger.stop()
            alive = true
        } else linger.restart()
    }

    screen: focusScreen
    visible: !hidden && alive
    anchors { top: true; left: true; bottom: true }
    implicitWidth: 440 * u
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "notification-popup"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region { item: list }

    Timer { id: linger; interval: Theme.ms(600); onTriggered: win.alive = false }

    ListView {
        id: list
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16 * win.u
        anchors.left: parent.left
        anchors.leftMargin: 16 * win.u
        width: 380 * win.u
        height: contentHeight
        interactive: false
        spacing: 10 * win.u
        model: ScriptModel { values: NotifsShared.popups.slice().reverse() }

        delegate: Item {
            id: slot
            required property var modelData
            readonly property real secs: modelData.expireTimeout > 0 ? modelData.expireTimeout / 1000 : 6
            readonly property bool sticky: modelData.expireTimeout === 0
                || (modelData.urgency === NotificationUrgency.Critical && modelData.expireTimeout < 0)
            property real remain: 1

            property real reveal: 0
            readonly property real r: Math.max(0, Math.min(1, reveal))

            width: list.width
            height: card.height * r

            NumberAnimation {
                id: enter
                target: slot
                property: "reveal"
                from: 0
                to: 1
                duration: Theme.ms(560)
                easing.type: Easing.OutBack
                easing.overshoot: 1.2
            }
            Component.onCompleted: enter.start()

            ListView.onRemove: { slot.ListView.delayRemove = true; leave.start() }
            SequentialAnimation {
                id: leave
                NumberAnimation {
                    target: slot
                    property: "reveal"
                    to: 0
                    duration: Theme.ms(300)
                    easing.type: Easing.InOutCubic
                }
                PropertyAction { target: slot; property: "ListView.delayRemove"; value: false }
            }

            Item {
                id: morph
                width: parent.width
                height: card.height
                anchors.bottom: parent.bottom
                opacity: Math.max(0, Math.min(1, slot.reveal * 2.2))
                x: -56 * win.u * (1 - slot.r)

                HoverHandler { id: hover }

                transform: Scale {
                    origin.x: 0
                    origin.y: morph.height / 2
                    xScale: 0.35 + 0.65 * slot.reveal
                    yScale: 0.72 + 0.28 * slot.reveal
                }

                NotificationCardShared {
                    id: card
                    width: parent.width
                    n: slot.modelData
                    u: win.u
                    popup: true
                    progress: slot.sticky ? -1 : slot.remain
                    scale: hover.hovered ? 1.015 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.ms(180); easing.type: Easing.OutCubic } }
                }
            }

            NumberAnimation {
                target: slot
                property: "remain"
                from: 1
                to: 0
                duration: slot.secs * 1000
                running: !slot.sticky
                paused: hover.hovered
                onFinished: NotifsShared.expirePopup(slot.modelData)
            }
        }
    }
}
