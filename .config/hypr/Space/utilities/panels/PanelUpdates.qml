import QtQuick
import "../common"
import "../ui"

// pending updates, same shared Updates as modern's bar
Column {
    spacing: 8
    Kit.Title { glyph: "󰚰"; text: "updates" }
    Hud { text: Updates.count ? Updates.count + " packages waiting" : "all up to date"; color: Theme.fg }
    Row {
        spacing: 6
        Button { label: "update now"; primary: true; visible: Updates.count > 0; onPressed: { Updates.run(); Ui.panel = "" } }
        Button { label: "check"; onPressed: Updates.recount() }
    }
}
