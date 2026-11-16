import QtQuick
import Quickshell
import Quickshell.Wayland
import "../style/common"

Variants {
    id: host
    required property string style
    property bool covered: false
    model: Quickshell.screens
    Scope {
        id: per
        required property var modelData
        readonly property bool shown: WidgetStateShared.editing !== modelData.name
        property bool ready: false
        WidgetModelShared { id: dm; screen: per.modelData; style: host.style }
        PanelWindow {
            id: frames
            screen: per.modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            updatesEnabled: !host.covered
            color: "transparent"
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "quickshell-widget-frames"
            Item {
                id: fill
                anchors.fill: parent
                visible: per.shown
                opacity: dm.shown
                Connections { target: fill.Window.window; enabled: !per.ready; function onFrameSwapped() { per.ready = true } }
                Repeater {
                    model: widgetsWin.item?.board.framed ?? []
                    Rectangle {
                        required property Item modelData
                        visible: modelData.visible
                        x: modelData.x
                        y: modelData.y
                        width: modelData.width
                        height: modelData.height
                        radius: Theme.r(10)
                        color: Theme.back(0.25)
                    }
                }
            }
        }
        LazyLoader {
            id: widgetsWin
            active: per.ready
            PanelWindow {
                readonly property alias board: board
                screen: per.modelData
                anchors { top: true; bottom: true; left: true; right: true }
                exclusionMode: ExclusionMode.Ignore
                updatesEnabled: !host.covered
                color: "transparent"
                WlrLayershell.layer: WlrLayer.Bottom
                WlrLayershell.namespace: "quickshell-widgets"
                WlrLayershell.keyboardFocus: WidgetStateShared.typing === per.modelData.name ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
                mask: Region { regions: board.hits }
                WidgetBoardShared { id: board; anchors.fill: parent; model: dm; visible: per.shown }
            }
        }
        Connections {
            target: WidgetStateShared
            function onEditingChanged() {
                if (WidgetStateShared.editing !== per.modelData.name && !dm.items.some(i => i.type === "term"))
                    Quickshell.execDetached([HyprShared.util + "/desk.sh", "hide", per.modelData.name])
            }
        }
        LazyLoader { active: !per.shown; WidgetsEditShared { model: dm } }
    }
}
