pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {

    readonly property var actions: ({
        lock: { cmd: "l=~/.config/hypr/utilities/session/lock.sh; if [ -x \"$l\" ]; then exec \"$l\"; elif command -v hyprlock >/dev/null; then exec hyprlock; else loginctl lock-session; fi", confirm: false },
        suspend: { cmd: "systemctl suspend", confirm: false },
        logout: { cmd: HyprShared.lua ? "hyprctl dispatch 'hl.dsp.exit()'" : "hyprctl dispatch exit", confirm: true },
        reboot: { cmd: "systemctl reboot || loginctl reboot", confirm: true },
        poweroff: { cmd: "systemctl poweroff || loginctl poweroff", confirm: true }
    })
    function cmd(id) { return actions[id].cmd }
    function confirm(id) { return actions[id].confirm }
    function act(id) { HyprShared.run(cmd(id)) }

    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: !!battery && battery.isLaptopBattery && battery.isPresent
    readonly property real charge: hasBattery ? (battery.percentage > 1 ? battery.percentage / 100 : battery.percentage) : 0
    readonly property bool charging: hasBattery && battery.state === UPowerDeviceState.Charging
    readonly property bool full: hasBattery && battery.state === UPowerDeviceState.FullyCharged
    readonly property bool discharging: hasBattery && battery.state === UPowerDeviceState.Discharging
}
