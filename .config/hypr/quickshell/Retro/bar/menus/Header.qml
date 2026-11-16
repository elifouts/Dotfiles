import QtQuick
import "../../common"

Controls.Title {
    property string title
    readonly property bool lead: ["Sound", "Updates", "Notifications"].includes(title)
    visible: !lead || extra.length > 0
    text: lead ? "" : title
    glyph: lead ? "" : ({ "Wi-Fi": "󰤨", Bluetooth: "󰂯" })[title] ?? ""
}
