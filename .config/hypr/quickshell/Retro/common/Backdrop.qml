import QtQuick
import Quickshell

Item {
    id: b
    property real t: 1
    property url source

    Rectangle { anchors.fill: parent; color: Theme.bg }
    Image {
        anchors.fill: parent
        source: "file://" + Quickshell.env("HOME") + "/.cache/retro-wall/current"
        fillMode: Image.PreserveAspectCrop
        smooth: false
        cache: false
        asynchronous: true
    }
    Rectangle { anchors.fill: parent; color: Theme.bg; opacity: 0.45 + 0.35 * b.t }
}
