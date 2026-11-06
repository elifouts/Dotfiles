import QtQuick
import "../../common"

Column {
    id: menu
    signal done()

    spacing: 8

    Header { title: "Updates" }
    Say {
        text: Updates.count ? Updates.count + " packages waiting" : "All up to date"
        font.pixelSize: 12
        color: Theme.fg
    }
    Row {
        spacing: 6
        Button { label: "Update now"; primary: true; visible: Updates.count > 0; onPressed: { Updates.run(); menu.done() } }
        Button { label: "Check"; onPressed: Updates.recount() }
    }
}
