import QtQuick

// glowing ball of light, the dots in the bar and every star on the map
ShaderEffect {
    property color tint: "white"
    property real core: 0.35
    property real glow: 1
    property real shade: 1
    fragmentShader: Qt.resolvedUrl("orb.frag.qsb")
}
