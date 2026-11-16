import QtQuick

Rectangle {
    id: field
    property alias text: input.text
    property string placeholder: ""
    property bool secret: false
    property bool readOnly: false
    property var keysTo: []
    signal accepted()
    function grab() { input.forceActiveFocus() }

    width: parent?.width ?? 280
    height: 22
    color: "transparent"
    border.width: 1
    border.color: input.activeFocus ? Theme.accent : Theme.low

    Text { id: caret; x: 6; anchors.verticalCenter: parent.verticalCenter; text: ">"; font.family: Theme.font; font.pixelSize: Theme.size; color: Theme.accent }
    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 6
        verticalAlignment: TextInput.AlignVCenter
        readOnly: field.readOnly
        echoMode: field.secret ? TextInput.Password : TextInput.Normal
        font.family: Theme.font
        font.pixelSize: Theme.size
        color: Theme.fg
        selectionColor: Theme.accent
        selectedTextColor: Theme.bg
        clip: true
        focus: true
        cursorDelegate: Rectangle {
            width: 8
            color: Theme.accent
            visible: input.activeFocus && blink.on
            Blink { id: blink; running: input.activeFocus }
        }
        Keys.forwardTo: field.keysTo
        onAccepted: field.accepted()
    }
    Type { x: 20; height: parent.height; visible: !input.text; text: field.placeholder; color: Theme.dim; caps: false }
}
