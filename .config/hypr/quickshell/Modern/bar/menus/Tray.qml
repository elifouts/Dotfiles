import QtQuick
import Quickshell
import "../../common"

Column {
    id: menu

    property bool open: false
    property var item: null
    signal run(string cmd)
    signal done()

    spacing: 10

    property var stack: []
    readonly property var current: stack.length > 0 ? stack[stack.length - 1] : (item ? item.menu : null)
    onItemChanged: stack = []
    onOpenChanged: if (!open) stack = []

    QsMenuOpener {
        id: opener
        menu: menu.current
    }

    Header {
        icon: menu.item ? menu.item.icon : ""
        title: menu.item ? (menu.item.tooltipTitle || menu.item.title || menu.item.id) : ""
    }

    Group {
        maxHeight: 380
        empty: "No menu"

        Entry {
            visible: menu.stack.length > 0
            glyph: ""
            label: "Back"
            onClicked: menu.stack = menu.stack.slice(0, -1)
        }

        Repeater {
            model: opener.children

            Item {
                id: entry
                required property var modelData
                width: parent.width
                height: modelData.isSeparator ? 9 : row.height

                Rectangle {
                    visible: entry.modelData.isSeparator
                    anchors.centerIn: parent
                    width: parent.width - 20
                    height: 1
                    color: Theme.alpha(Theme.fg, 0.08)
                }

                Entry {
                    id: row
                    visible: !entry.modelData.isSeparator
                    readonly property bool check: entry.modelData.buttonType !== QsMenuButtonType.None
                    readonly property bool checked: entry.modelData.checkState === Qt.Checked
                    label: (entry.modelData.text || "").replace(/_(?=[^_])/g, "")
                    iconSource: entry.modelData.icon || ""
                    glyph: check ? (checked ? (entry.modelData.buttonType === QsMenuButtonType.RadioButton ? "" : "") : (entry.modelData.buttonType === QsMenuButtonType.RadioButton ? "" : "")) : ""
                    trailing: entry.modelData.hasChildren ? "" : ""
                    enabledRow: entry.modelData.enabled
                    onClicked: {
                        if (entry.modelData.hasChildren) {
                            menu.stack = menu.stack.concat([entry.modelData])
                        } else {
                            entry.modelData.triggered()
                            menu.done()
                        }
                    }
                }
            }
        }
    }
}
