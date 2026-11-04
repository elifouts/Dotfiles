import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property int fade: 300
    property var held: ({})
    property int captured: 0
    property bool revealing: false
    property real progress: 0
    NumberAnimation on progress {
        running: root.captured > 0 && !root.revealing
        to: 0.9
        duration: 800
        easing.type: Easing.OutCubic
    }
    NumberAnimation on progress {
        running: root.revealing
        to: 1
        duration: 120
    }

    function reveal() {
        held = {}
        revealing = true
        done.start()
    }

    IpcHandler {
        target: "transition"
        function covered(): bool { return root.captured >= Quickshell.screens.length }
        function hold(zones: string): void { root.held = JSON.parse(zones) }
        function reveal(): void { root.reveal() }
    }

    Timer { interval: 12000; running: !root.revealing; onTriggered: root.reveal() }
    Timer { id: done; interval: root.fade + 50; onTriggered: Qt.quit() }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "style-transition"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Item {
                anchors.fill: parent
                OpacityAnimator on opacity {
                    running: root.revealing
                    to: 0
                    duration: root.fade
                    easing.type: Easing.InOutSine
                }

                ScreencopyView {
                    id: frame
                    anchors.fill: parent
                    captureSource: modelData
                    live: false
                    paintCursor: false
                    onHasContentChanged: if (hasContent) root.captured++
                }
                MultiEffect {
                    anchors.fill: parent
                    source: frame
                    visible: frame.hasContent
                    autoPaddingEnabled: false
                    blurEnabled: true
                    blurMax: 48
                    blur: frame.hasContent ? 1 : 0
                    Behavior on blur { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 220
                    height: 4
                    radius: 2
                    color: Qt.rgba(1, 1, 1, 0.18)
                    opacity: frame.hasContent ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                    Rectangle {
                        width: parent.width * root.progress
                        height: parent.height
                        radius: parent.radius
                        color: "white"
                    }
                }
            }
        }
    }

    Variants {
        model: {
            const zones = []
            for (const screen of Quickshell.screens)
                for (const edge of [0, 1, 2, 3]) zones.push({ screen, edge })
            return zones
        }
        PanelWindow {
            required property var modelData
            readonly property int edge: modelData.edge
            readonly property int zone: root.held[modelData.screen.name]?.[edge] ?? 0
            screen: modelData.screen
            visible: zone > 0
            anchors { left: edge !== 2; right: edge !== 0; top: edge !== 3; bottom: edge !== 1 }
            implicitWidth: 1
            implicitHeight: 1
            exclusiveZone: zone
            color: "transparent"
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "style-transition"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        }
    }
}
