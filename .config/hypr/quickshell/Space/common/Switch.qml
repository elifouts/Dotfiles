import QtQuick

Controls.Toggle {
    property bool checked: false
    property bool hot: false
    signal toggled()
    on: checked
    onFlip: toggled()
}
