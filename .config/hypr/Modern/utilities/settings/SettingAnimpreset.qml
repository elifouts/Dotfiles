import QtQuick
import "Motion.js" as Motion

Dropdown {
    id: control

    property var def
    readonly property var curve: Store.values["animation.curve"] || Motion.CURVE

    label: "Preset"
    current: Store.values["animation.preset"] || "theme"
    options: Motion.PRESET_OPTIONS

    onPicked: v => Motion.pick(Store, v, control.curve)

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: Store.reset("animation")
    }
}
