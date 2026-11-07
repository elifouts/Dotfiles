import QtQuick
import "../../common"

Item {
    id: row
    property string glyph
    property string label
    property string sub
    property string trailing
    property bool active: false
    property bool busy: false
    property bool gear: false
    signal clicked()
    signal rightClicked()
    signal settingsClicked()
    function cheer() {}

    width: parent?.width ?? 280
    height: Theme.menuRow

    Controls.Line {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width - (row.gear ? 24 : 0)
        glyph: row.glyph
        text: row.label
        value: row.sub || row.trailing
        lit: row.active
        onClicked: m => m.button === Qt.RightButton ? row.rightClicked() : row.clicked()
    }
    Text {
        visible: row.gear
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        text: ""
        font.family: Theme.font
        font.pixelSize: 12
        color: cog.containsMouse ? Theme.accent : Theme.dim
        MouseArea { id: cog; anchors.fill: parent; anchors.margins: -5; hoverEnabled: true; onClicked: row.settingsClicked() }
    }
}
