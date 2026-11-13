pragma Singleton

import QtQuick
import "../../shared"

ThemeBaseShared {
    readonly property string font: StoreShared.values["space.font"] || "JetBrainsMono Nerd Font"
    sans: font
    frozen: Ui.holdTheme
    rounding: 0
    round: 0
    lines: 1
    caps: Font.AllUppercase
    tracking: 1.6
    menuRow: 24
    fg: c(15, "#d8e2f0")
    bg: wal ? wal.special.background : "#05070c"
    edge: alpha(accent, 0.35)

    readonly property int bar: 24
    readonly property int starGap: 16
    readonly property int open: Math.round(slow * 0.6)

    Connections { target: StoreShared; function onThemeApplied() { reload() } }
}
