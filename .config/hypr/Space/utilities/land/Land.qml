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
        asTheme: true
        Behavior on pan { NumberAnimation { duration: 1400; easing.type: Easing.InOutCubic } }
    }

    // touchdown: falls in from high up and a flash of the new sky clears
    Rectangle { id: flash; anchors.fill: parent; color: Theme.accent; opacity: 0 }
    Connections {
        target: World
        function onLanded() { if (!World.hopping) landing.restart() }
        function onHopped(h) { land.fade = 900; land.hue = h; release.stop(); fadeOff.stop(); hopping.restart() }
    }
    // moonset: the moon goes down into a sunset while the colours glide to the new ones, drops back in from the top
    // as the glow settles, then wal gets told
    SequentialAnimation {
        id: hopping
        ParallelAnimation {
            NumberAnimation { target: land; property: "lift"; to: -0.9; duration: 450; easing.type: Easing.InSine }
            NumberAnimation { target: land; property: "glow"; to: 1; duration: 450; easing.type: Easing.OutQuad }
        }
        ScriptAction { script: land.lift = 0.9 }
        ParallelAnimation {
            NumberAnimation { target: land; property: "lift"; to: 0; duration: 500; easing.type: Easing.OutSine }
            NumberAnimation { target: land; property: "glow"; to: 0; duration: 500; easing.type: Easing.InQuad }
        }
        ScriptAction { script: { World.hopLand(); release.restart() } }
    }
    // hand the colours back to Theme once wal's surely done, the glide's still on in case they're off a hair
    Timer { id: release; interval: 4000; onTriggered: { land.hue = -1; fadeOff.restart() } }
    Timer { id: fadeOff; interval: 1000; onTriggered: land.fade = 0 }
    ParallelAnimation {
        id: landing
        NumberAnimation { target: land; property: "zoom"; from: 2.6; to: 1; duration: 1300; easing.type: Easing.OutCubic }
        NumberAnimation { target: flash; property: "opacity"; from: 0.5; to: 0; duration: 900; easing.type: Easing.OutQuad }
    }

    Desk { anchors.fill: parent; model: win.desk; visible: Ui.editing !== win.screen?.name }
}
