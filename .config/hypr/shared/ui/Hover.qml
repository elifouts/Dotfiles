import QtQuick

// MouseArea that tracks hover and shows the hand, nearly every clickable thing wants this
MouseArea {
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
}
