import QtQuick
import "../style/common"
import "../style/bar/menus"

Column {
    id: menu
    signal done()

    spacing: 8

    Header { title: "Updates" }
    Say {
        text: UpdatesShared.count ? UpdatesShared.count + " packages waiting" : "All up to date"
        font.pixelSize: 12
        color: Theme.fg
    }
    Row {
        spacing: 6
        Button { label: "Update now"; primary: true; visible: UpdatesShared.count > 0; onPressed: { UpdatesShared.run(); menu.done() } }
        Button { label: "Check"; onPressed: UpdatesShared.recount() }
    }
}
