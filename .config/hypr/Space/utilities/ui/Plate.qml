import QtQuick
import QtQuick.Shapes
import "../common"

Shape {
    id: plate
    property real cut: 10
    property real fill: 0.82
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
        strokeWidth: 1
        strokeColor: Theme.alpha(Theme.accent, 0.35)
        fillColor: Theme.alpha(Theme.bg, plate.fill)
        startX: plate.cut; startY: 0
        PathLine { x: plate.width; y: 0 }
        PathLine { x: plate.width; y: plate.height }
        PathLine { x: 0; y: plate.height }
        PathLine { x: 0; y: plate.cut }
        PathLine { x: plate.cut; y: 0 }
    }
}
