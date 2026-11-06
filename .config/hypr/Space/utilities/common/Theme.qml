pragma Singleton

import QtQuick

ThemeBase {
    readonly property string font: Store.values["space.font"] || "JetBrainsMono Nerd Font"
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
    readonly property int quick: ms(180)
    readonly property int slow: ms(560)
    readonly property int open: Math.round(slow * 0.6)
    readonly property color faint: alpha(fg, 0.14)
    readonly property color glass: panel
    readonly property color void_: Qt.darker(bg, 2.2)

    Connections { target: Store; function onThemeApplied() { reload() } }
}
