import QtQuick
import "../common"

Item {
    property bool atRight: false
    property bool atBottom: false
    width: 7; height: 7
    Rectangle { width: 7; height: 1; y: parent.atBottom ? 6 : 0; color: Theme.accent; opacity: 0.9 }
    Rectangle { width: 1; height: 7; x: parent.atRight ? 6 : 0; color: Theme.accent; opacity: 0.9 }
}
