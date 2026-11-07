import QtQuick
import "../../shared"

SequentialAnimation {
    id: pop
    property Item target
    property string label
    property string last
    onLabelChanged: { if (last !== "" && label !== "") restart(); last = label }
    NumberAnimation { target: pop.target; property: "scale"; to: 1.06; duration: Theme.fast; easing.type: Easing.OutCubic }
    SettleShared { target: pop.target; property: "scale"; to: 1; duration: Theme.move }
}
