pragma Singleton

import QtQuick

// modern's theme, square, in space's font, outlined in accent
ThemeBase {
    // settings > fonts, one family for the whole theme
    readonly property string font: Store.values["space.font"] || "JetBrainsMono Nerd Font"
    sans: font
    rounding: 0
    round: 0
    lines: 1
    caps: Font.AllUppercase
    tracking: 1.6
    fg: c(15, "#d8e2f0")
    bg: wal ? wal.special.background : "#05070c"
    edge: alpha(accent, 0.35)

    readonly property int bar: 24
    // the overview flies stars out from these same spots
    readonly property int starLeft: 22
    readonly property int starGap: 16
    readonly property int quick: ms(180)
    readonly property int slow: ms(560)
    // how long a box takes to drop open, the launcher's timing, everything uses it
    readonly property int open: Math.round(slow * 0.6)
    readonly property color faint: alpha(fg, 0.14)
    readonly property color glass: panel
    readonly property color void_: Qt.darker(bg, 2.2)

    // wal writes colors.json in pieces and the watch can land on a half file, so read both again once the apply is done
    Connections { target: Store; function onThemeApplied() { reload() } }
}
