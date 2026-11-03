import QtQuick

// NumberAnimation on hyprland's window-in curve
NumberAnimation {
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Theme.settle
}
