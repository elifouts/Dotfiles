import QtQuick

Item {
    id: t
    property string text
    property alias font: label.font
    property alias color: label.color
    property alias elide: label.elide
    property alias wrapMode: label.wrapMode
    property alias lineHeight: label.lineHeight
    property alias textFormat: label.textFormat
    property alias horizontalAlignment: label.horizontalAlignment
    property alias verticalAlignment: label.verticalAlignment
    property alias leftPadding: label.leftPadding
    property alias rightPadding: label.rightPadding
    property alias contentWidth: label.contentWidth
    property alias contentHeight: label.contentHeight
    property bool type: true
    property bool caps: true
    property real n: 1e6

    implicitWidth: Math.ceil(tm.advanceWidth) + label.leftPadding + label.rightPadding
    implicitHeight: label.implicitHeight
    baselineOffset: label.baselineOffset
    TextMetrics { id: tm; font: label.font; text: t.text }

    function run() {
        if (!type || !visible || !Theme.animates || textFormat !== Text.PlainText) { tick.stop(); n = 1e6; return }
        tick.duration = Math.min(320, 40 + text.length * 12)
        tick.restart()
    }
    onTextChanged: run()
    onVisibleChanged: if (visible && n < 1e6) run()
    Component.onCompleted: run()
    NumberAnimation { id: tick; target: t; property: "n"; from: 0; to: t.text.length + 1; onRunningChanged: if (!running) t.n = 1e6 }

    Text {
        id: label
        anchors.fill: parent
        text: t.n > t.text.length ? t.text : t.text.slice(0, Math.floor(t.n)) + "█"
        font.family: Theme.font
        font.pixelSize: Theme.size
        font.letterSpacing: t.caps ? Theme.tracking : 0
        font.capitalization: t.caps ? Font.AllUppercase : Font.MixedCase
        font.hintingPreference: Font.PreferFullHinting
        color: Theme.fg
        verticalAlignment: Text.AlignVCenter
        textFormat: Text.PlainText
        renderType: Text.NativeRendering
    }
}
