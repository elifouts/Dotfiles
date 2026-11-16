import QtQuick

Rectangle {
    id: box
    property string title
    property string note
    property bool double: false
    property real fill: 1
    property color ink: Theme.line
    color: Theme.back(fill)

    Rectangle {
        visible: box.double
        anchors.fill: parent
        anchors.margins: 3
        color: "transparent"
        border.width: 1
        border.color: box.ink
    }
    Rectangle { width: 1; height: parent.height; color: box.ink }
    Rectangle { x: parent.width - 1; width: 1; height: parent.height; color: box.ink }
    Rectangle { width: head.visible ? head.x : parent.width; height: 1; color: box.ink }
    Rectangle { visible: head.visible; x: head.x + head.width; width: parent.width - x; height: 1; color: box.ink }
    Rectangle { y: parent.height - 1; width: tail.visible ? tail.x : parent.width; height: 1; color: box.ink }
    Rectangle { visible: tail.visible; x: tail.x + tail.width; y: parent.height - 1; width: parent.width - x; height: 1; color: box.ink }
    Item {
        id: head
        visible: box.title !== ""
        x: 10
        y: -height / 2
        width: headText.implicitWidth + 12
        height: headText.implicitHeight
        Rectangle { width: parent.width; height: parent.height / 2; color: box.color }
        Type { id: headText; x: 6; text: box.title; color: Theme.accent }
    }
    Item {
        id: tail
        visible: box.note !== ""
        x: parent.width - width - 10
        y: parent.height - height / 2
        width: tailText.implicitWidth + 12
        height: tailText.implicitHeight
        Rectangle { y: parent.height / 2; width: parent.width; height: parent.height / 2; color: box.color }
        Type { id: tailText; x: 6; text: box.note; color: Theme.dim; font.pixelSize: Theme.size - 3 }
    }
}
