import QtQuick
import Quickshell
import "../../../shared"
import "../../common"

Column {
    id: pt
    spacing: 10
    readonly property bool holdOpen: cal.holdOpen

    SystemClock { id: clock; precision: SystemClock.Minutes }
    DecodeText {
        caps: false
        text: Theme.clock(clock.date)
        font.pixelSize: 34
        font.weight: Font.ExtraLight
        color: Theme.fg
    }
    CalendarShared { id: cal; width: parent.width; open: Ui.panel === "time" }
}
