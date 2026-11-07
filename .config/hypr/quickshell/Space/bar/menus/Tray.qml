import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../../common"

Column {
    id: tray
    spacing: 4
    property var item: null

    QsMenuOpener { id: opener; menu: tray.item?.menu ?? null }

    Controls.Title { glyph: "󱊔"; text: tray.item ? (tray.item.tooltipTitle || tray.item.title || tray.item.id) : "tray" }
    Repeater {
        model: tray.item ? [] : SystemTray.items.values
        Controls.Line {
            required property var modelData
            glyph: "•"
            text: modelData.tooltipTitle || modelData.title || modelData.id
            value: modelData.hasMenu ? "›" : ""
            onClicked: m => {
                if (m.button === Qt.RightButton || modelData.onlyMenu) { if (modelData.hasMenu) tray.item = modelData }
                else { modelData.activate(); Ui.panel = "" }
            }
        }
    }
    Controls.Line { visible: !!tray.item; glyph: "‹"; text: "back"; onClicked: tray.item = null }
    Repeater {
        model: opener.children.values.filter(e => !e.isSeparator)
        Controls.Line {
            required property var modelData
            text: modelData.text
            enabled: modelData.enabled
            opacity: enabled ? 1 : 0.4
            onClicked: { modelData.triggered(); Ui.panel = "" }
        }
    }
}
