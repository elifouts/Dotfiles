pragma Singleton

import QtQuick
import "../../shared"

ThemeBaseShared {
    readonly property string fallback: Qt.fontFamilies().includes("Terminess Nerd Font Mono") ? "Terminess Nerd Font Mono" : "JetBrainsMono Nerd Font Mono"
    readonly property string font: StoreShared.values["retro.font"] || fallback
    readonly property int size: StoreShared.values["retro.size"] || 14
    sans: font
    rounding: 0
    round: 0
    lines: 1
    caps: Font.AllUppercase
    tracking: 1
    menuRow: 22
    osdFill: 0.86
    bg: wal ? wal.special.background : "#040e06"
    fg: c(7, "#5ae27c")
    edge: alpha(accent, 0.45)

    readonly property int bar: 24
    readonly property color low: alpha(accent, 0.18)
    readonly property color line: alpha(accent, 0.55)
    readonly property int open: ms(150)
    function solid(a) { return back(a ?? 1) }

    Connections { target: StoreShared; function onThemeApplied() { reload() } }
}
