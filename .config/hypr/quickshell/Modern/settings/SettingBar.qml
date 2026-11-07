import QtQuick
import "../../shared"

Dropdown {

    property var def

    label: "Bar"
    options: [
        { v: "waybar", l: "Waybar" },
        { v: "quickshell", l: "Quickshell bar" }
    ]
    current: StoreShared.bar
    onPicked: v => { if (v !== StoreShared.bar) StoreShared.applyBar(v) }
}
