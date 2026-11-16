import QtQuick
import Quickshell
import "../../../shared"
import "../../common"

Column {
    id: pt
    spacing: 10
    readonly property bool holdOpen: cal.holdOpen

    SystemClock { id: clock; precision: SystemClock.Minutes }
    Type {
        caps: false
        text: Theme.clock(clock.date)
        font.pixelSize: 34
        font.weight: Font.Normal
        color: Theme.fg
    }
    CalendarShared { id: cal; width: parent.width; open: Ui.panel === "time" }
}
