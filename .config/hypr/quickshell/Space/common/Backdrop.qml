import QtQuick
import "../wallpaper"

Item {
    id: b

    property real t: 1
    property url source

    Terrain { anchors.fill: parent; layer.enabled: true }
    Rectangle { anchors.fill: parent; color: Theme.void_; opacity: 0.35 + 0.3 * b.t }
}
