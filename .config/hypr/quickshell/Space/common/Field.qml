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
    height: 24
    color: Theme.back(0.5)
    border.width: 1
    border.color: input.activeFocus ? Theme.accent : Theme.faint

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 8
        verticalAlignment: TextInput.AlignVCenter
        readOnly: field.readOnly
        echoMode: field.secret ? TextInput.Password : TextInput.Normal
        font.family: Theme.font
        font.pixelSize: 12
        color: Theme.fg
        clip: true
        focus: true
        Keys.forwardTo: field.keysTo
        onAccepted: field.accepted()
    }
    DecodeText { x: 8; height: parent.height; visible: !input.text; text: field.placeholder; color: Theme.alpha(Theme.fg, 0.3) }
}
