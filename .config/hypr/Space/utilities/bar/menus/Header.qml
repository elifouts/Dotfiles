import QtQuick
import "../../common"

Controls.Title {
    property string title
    text: title
    glyph: ({ "Wi-Fi": "󰤨", Bluetooth: "󰂯", Sound: "󰕾", Updates: "󰚰", Notifications: "󰂚" })[title] ?? ""
}
