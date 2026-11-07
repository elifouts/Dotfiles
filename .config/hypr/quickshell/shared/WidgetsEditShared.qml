import QtQuick
import Quickshell
import Quickshell.Wayland
import "../style/common"

PanelWindow {
    id: win

    required property var model
    screen: model.screen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-widgets"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Rectangle { anchors.fill: parent; color: Theme.void_; opacity: 0.55 }

    WidgetBoardShared { anchors.fill: parent; model: win.model; editing: true }

    WidgetEditorShared {
        model: win.model
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 28
    }

    Item {
        focus: true
        Keys.onEscapePressed: WidgetStateShared.editing = ""
        Keys.onDeletePressed: if (win.model.picked >= 0) win.model.remove(win.model.picked)
    }
}
