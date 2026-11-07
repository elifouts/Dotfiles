import QtQuick
import "../../shared"
import "../common"

Column {
    id: control

    property var def

    readonly property bool qs: StoreShared.bar === "quickshell"
    readonly property var styles: (qs ? StoreShared.quickshell : StoreShared.waybar).styles || []
    readonly property string active: qs ? StoreShared.quickshellActive : StoreShared.waybarActive
    readonly property var shown: styles.find(s => s.id === active) ?? null

    Dropdown {
        id: dd
        width: parent.width
        label: "Style"
        options: control.styles.map(s => ({ v: s.id, l: s.name, preview: s.image !== "" ? "file://" + s.image : "" }))
        current: control.active
        onPicked: v => { if (v !== control.active) control.qs ? StoreShared.applyQuickshell(v) : StoreShared.applyWaybar(v) }
    }

    Item {
        width: parent.width
        height: preview.visible ? preview.height + 14 : 0
        Behavior on height { NumberAnimation { duration: Theme.ms(240); easing.type: Easing.OutCubic } }
        clip: true

        Image {
            id: preview
            x: Theme.pad + 12
            width: parent.width - (Theme.pad + 12) * 2
            height: width * 70 / 2000
            visible: !dd.open && !!control.shown && control.shown.image !== ""
            source: control.shown && control.shown.image !== "" ? "file://" + control.shown.image : ""
            sourceSize.width: 1000
            fillMode: Image.PreserveAspectFit
            opacity: 0.8
        }
    }
}
