import QtQuick
import "../../shared"
import "../../shared/MotionShared.js" as Motion

Dropdown {
    id: control

    property var def
    readonly property var curve: StoreShared.values["animation.curve"] || Motion.CURVE

    label: "Preset"
    current: StoreShared.values["animation.preset"] || "theme"
    options: Motion.PRESET_OPTIONS

    onPicked: v => Motion.pick(StoreShared, v, control.curve)

    ResetArea { key: "animation" }
}
