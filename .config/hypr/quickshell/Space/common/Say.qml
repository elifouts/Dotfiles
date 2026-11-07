import QtQuick

DecodeText {
    id: say
    caps: false
    implicitWidth: probe.implicitWidth + leftPadding + rightPadding
    implicitHeight: probe.implicitHeight
    baselineOffset: probe.baselineOffset
    property int replay
    onReplayChanged: { was = ""; k = 1; run() }
    Text { id: probe; visible: false; text: say.text; font: say.font; lineHeight: say.lineHeight }
}
