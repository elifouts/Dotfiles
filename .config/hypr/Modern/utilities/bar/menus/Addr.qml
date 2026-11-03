import QtQuick
import "../../common"

Row {
    property alias addr: a
    property alias gw: g
    width: parent ? parent.width : 0
    spacing: 6
    Field { id: a; width: (parent.width - 6) / 2; placeholder: "Address"; onAccepted: g.grab() }
    Field { id: g; width: (parent.width - 6) / 2; placeholder: "Gateway" }
}
