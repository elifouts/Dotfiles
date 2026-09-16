import QtQuick
import Quickshell
import Quickshell.Wayland
import "./theme" as RetroTheme

PanelWindow {
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: "transparent"
    property bool closing: false

    Rectangle {
        id: card
        width: 520
        height: 330
        anchors.centerIn: parent
        color: RetroTheme.Theme.surface
        border.color: RetroTheme.Theme.accent
        border.width: 1
        radius: 4
        opacity: 0
        scale: 0.96
        Component.onCompleted: openAnimation.start()
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }
        ParallelAnimation {
            id: openAnimation
            NumberAnimation { target: card; property: "opacity"; to: 1; duration: 140; easing.type: Easing.OutCubic }
            NumberAnimation { target: card; property: "scale"; to: 1; duration: 240; easing.type: Easing.OutBack }
        }
        ParallelAnimation {
            id: closeAnimation
            NumberAnimation { target: card; property: "opacity"; to: 0; duration: 100; easing.type: Easing.InCubic }
            NumberAnimation { target: card; property: "scale"; to: 0.96; duration: 140; easing.type: Easing.InCubic }
            onFinished: Qt.quit()
        }
        Column {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 12
            Text { text: "// HYPR PROFILES"; color: RetroTheme.Theme.accent; font.family: "JetBrains Mono"; font.pixelSize: 19; font.bold: true }
            Text { text: "BAR: QUICKSHELL  |  MODERN PROFILES: WAYBAR"; color: RetroTheme.Theme.muted; font.family: "JetBrains Mono"; font.pixelSize: 11 }
            Repeater {
                model: ["Retro", "Modern", "Modern Laptop"]
                Rectangle {
                    width: parent.width
                    height: 52
                    color: mouse.containsMouse ? RetroTheme.Theme.surfaceAlt : RetroTheme.Theme.background
                    border.color: mouse.containsMouse ? RetroTheme.Theme.accentAlt : RetroTheme.Theme.border
                    border.width: 1
                    scale: mouse.containsMouse ? 1.02 : 1
                    Behavior on color { ColorAnimation { duration: 110 } }
                    Behavior on border.color { ColorAnimation { duration: 110 } }
                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                    Text { anchors.centerIn: parent; text: modelData + (modelData === "Retro" ? "  [Quickshell]" : "  [Waybar]"); color: RetroTheme.Theme.foreground; font.family: "JetBrains Mono"; font.pixelSize: 15 }
                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: { Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/utilities/load-profile.sh", modelData]); close() }
                    }
                }
            }
            Text { text: "ESC  close"; color: RetroTheme.Theme.muted; font.family: "JetBrains Mono"; font.pixelSize: 12 }
        }
        Keys.onEscapePressed: close()
        focus: true
    }

    function close() {
        if (closing) return;
        closing = true;
        closeAnimation.start();
    }
}
