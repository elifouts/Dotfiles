import QtQuick

Controls.Toggle {
    property bool checked: false
    signal toggled()
    on: checked
    onFlip: toggled()
}
