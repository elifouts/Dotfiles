import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../shared"

Scope {
    IpcHandler {
        target: "widgets"
        function toggle(): void { WidgetStateShared.toggle() }
    }

    Variants {
        model: Quickshell.screens
        Scope {
            id: per
            required property var modelData
            WidgetModelShared { id: dm; screen: per.modelData; style: "modern" }
            PanelWindow {
                screen: per.modelData
                anchors { top: true; bottom: true; left: true; right: true }
                exclusionMode: ExclusionMode.Ignore
                color: "transparent"
                WlrLayershell.layer: WlrLayer.Bottom
                WlrLayershell.namespace: "quickshell-widgets"
                WlrLayershell.keyboardFocus: WidgetStateShared.typing === per.modelData.name ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
                WidgetBoardShared { anchors.fill: parent; model: dm; visible: WidgetStateShared.editing !== per.modelData.name }
            }
            LazyLoader { active: WidgetStateShared.editing === per.modelData.name; WidgetsEditShared { model: dm } }
        }
    }
}
