import QtQuick
import "../style/common"

NumberAnimation {
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Theme.settle
}
