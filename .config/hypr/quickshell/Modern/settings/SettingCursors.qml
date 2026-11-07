import QtQuick
import "../../shared"

Dropdown {

    property var def

    label: "Cursor theme"
    options: StoreShared.cursors.map(c => ({ v: c.toLowerCase(), l: c }))
    current: String(StoreShared.values["cursor.theme"] || "").toLowerCase()
    onPicked: v => StoreShared.set("cursor.theme", StoreShared.cursors.find(c => c.toLowerCase() === v))

    ResetArea { key: "cursor.theme" }
}
