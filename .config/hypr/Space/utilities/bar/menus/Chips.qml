import QtQuick
import "../../common"

Flow {
    id: chips
    property var options: []
    property string value
    signal picked(string v)
    width: parent?.width ?? 280
    spacing: 6
    Repeater {
        model: chips.options
        Button {
            required property var modelData
            label: modelData[1]
            primary: chips.value === modelData[0]
            onPressed: { chips.value = modelData[0]; chips.picked(chips.value) }
        }
    }
}
