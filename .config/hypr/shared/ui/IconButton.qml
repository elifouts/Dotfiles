import QtQuick

// clickable icon/text that lights up on hover. hit area is a bit bigger than the glyph cause tiny icons suck to click
Label {
    id: g

    property color hot: Theme.accent
    property color idle: Theme.dim
    property real reach: 5
    readonly property bool hovered: area.containsMouse
    signal clicked()

    color: area.containsMouse ? hot : idle

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -g.reach
        hoverEnabled: true
        onClicked: g.clicked()
    }
}
