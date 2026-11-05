import QtQuick

ShaderEffect {
    property color tint: "white"
    property real core: 0.35
    property real glow: 1
    property real shade: 1
    fragmentShader: Qt.resolvedUrl("orb.frag.qsb")
}
