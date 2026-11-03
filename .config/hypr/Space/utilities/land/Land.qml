import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../common"
import "../desk"

// one monitor's wallpaper, workspaces pan across it
PanelWindow {
    id: win

    required property var desk
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "black"
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "space-wall"
    WlrLayershell.keyboardFocus: Ui.typing === screen?.name ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // every monitor pans with the focused workspace, together
    readonly property int ws: Hyprland.focusedWorkspace?.id ?? 1

    Terrain {
        id: land
        anchors.fill: parent
        ws: win.ws
        screenX: win.screen?.x ?? 0
        Behavior on pan { NumberAnimation { duration: 1400; easing.type: Easing.InOutCubic } }
    }

    // touchdown: falls in from high up and a flash of the new sky clears
    Rectangle { id: flash; anchors.fill: parent; color: Theme.accent; opacity: 0 }
    Connections {
        target: World
        function onLanded() { landing.restart() }
    }
    ParallelAnimation {
        id: landing
        NumberAnimation { target: land; property: "zoom"; from: 2.6; to: 1; duration: 1300; easing.type: Easing.OutCubic }
        NumberAnimation { target: flash; property: "opacity"; from: 0.5; to: 0; duration: 900; easing.type: Easing.OutQuad }
    }

    Desk { anchors.fill: parent; model: win.desk; visible: Ui.editing !== win.screen?.name }
}
