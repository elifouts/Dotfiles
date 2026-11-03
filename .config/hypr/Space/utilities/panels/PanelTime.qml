import QtQuick
import Quickshell
import "../common"
import "../ui"

// the time big and the shared calendar + todos, same one modern's pill and the desk use
Column {
    id: pt
    spacing: 10
    // the wing stays down while the todo box has the keys
    readonly property bool holdOpen: cal.holdOpen

    SystemClock { id: clock; precision: SystemClock.Minutes }
    Hud {
        caps: false
        text: Qt.formatTime(clock.date, Store.values["space.clock24"] === false ? "h:mm" : "HH:mm")
        font.pixelSize: 34
        font.weight: Font.ExtraLight
        color: Theme.fg
    }
    Calendar { id: cal; width: parent.width; open: Ui.panel === "time" }
}
