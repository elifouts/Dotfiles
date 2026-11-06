import QtQuick
import "../../common"

Kit.Title {
    property string title
    text: title
    glyph: ({ "Wi-Fi": "󰤨", Bluetooth: "󰂯", Sound: "󰕾", Updates: "󰚰", Notifications: "󰂚" })[title] ?? ""
}
