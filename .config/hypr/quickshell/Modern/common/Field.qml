import QtQuick
import "../../shared"

Rectangle {
    id: field

    property alias text: input.text
    property string placeholder: ""
    property bool secret: false
    property bool readOnly: false
    property bool shown: false
    signal accepted()

    function grab() { input.forceActiveFocus() }

    width: parent ? parent.width : 0
    height: 34
    radius: Math.min(Theme.rounding, 8)
    color: Theme.alpha(Theme.fg, input.activeFocus ? 0.1 : 0.07)
    border.width: 1
    border.color: input.activeFocus ? Theme.alpha(Theme.accent, 0.6) : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.ms(120) } }
    Behavior on border.color { ColorAnimation { duration: Theme.ms(120) } }

    TextInput {
        id: input
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: eye.visible ? eye.left : parent.right
        anchors.rightMargin: eye.visible ? 8 : 12
        anchors.verticalCenter: parent.verticalCenter
        readOnly: field.readOnly
        echoMode: field.secret && !field.shown ? TextInput.Password : TextInput.Normal
        font.family: Theme.sans
        font.pixelSize: 13
        color: Theme.bright
        selectionColor: Theme.alpha(Theme.accent, 0.5)
        selectByMouse: true
        clip: true
        onAccepted: field.accepted()

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            visible: input.text === ""
            text: field.placeholder
            elide: Text.ElideRight
            font: input.font
            color: Theme.dim
        }
    }

    LabelShared {
        id: eye
        visible: field.secret
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: field.shown ? "\uf070" : "\uf06e"
        font.pixelSize: 12
        color: eyeArea.containsMouse ? Theme.fg : Theme.dim
        MouseArea { id: eyeArea; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: field.shown = !field.shown }
    }
}
