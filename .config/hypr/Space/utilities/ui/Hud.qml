import QtQuick
import "../common"
import "decode.js" as Decode

// the one text style, small caps and wide tracking. every change decodes like the launcher rows (decode.js)
Item {
    id: hud
    property string text
    property alias font: label.font
    property alias color: label.color
    property alias elide: label.elide
    property alias wrapMode: label.wrapMode
    property alias textFormat: label.textFormat
    property alias horizontalAlignment: label.horizontalAlignment
    property alias verticalAlignment: label.verticalAlignment
    property alias leftPadding: label.leftPadding
    property alias rightPadding: label.rightPadding
    property alias contentWidth: label.contentWidth
    property alias contentHeight: label.contentHeight
    property bool decode: true
    // false for normal text (titles, clocks), same decode just no small caps
    property bool caps: true

    // sized from the final text so rows don't wobble while it types in
    implicitWidth: Math.ceil(tm.advanceWidth) + label.leftPadding + label.rightPadding
    TextMetrics { id: tm; font: label.font; text: hud.text }
    implicitHeight: label.implicitHeight

    property string from: ""
    // what it was decoding toward, plain so reading it never re-runs the binding
    property string was: ""
    property real k: 1
    property bool fresh: true
    property int wait: 0
    // first show types in (staggered with whatever else just appeared), later changes ripple through
    function run() {
        if (!decode || textFormat !== Text.PlainText) { from = was = text; k = 1; return }
        // not on screen yet, wait till it is so the typing isn't wasted on nobody
        if (!visible) { if (!fresh) { from = was = text; k = 1 } return }
        from = k < 1 ? Decode.frame(from, was, k) : was
        was = text
        wait = fresh ? Decode.stagger() : 0
        k = 0
        morph.restart()
        fresh = false
    }
    onTextChanged: run()
    onVisibleChanged: if (visible && fresh) run()
    Component.onCompleted: run()
    SequentialAnimation {
        id: morph
        PauseAnimation { duration: hud.wait }
        NumberAnimation { target: hud; property: "k"; to: 1; duration: Decode.ms(hud.text.length, hud.wait > 0 || hud.from === "") }
    }
    readonly property string shown: Decode.frame(from, was, k)

    Text {
        id: label
        anchors.fill: parent
        text: hud.shown
        font.family: Theme.font
        font.pixelSize: 11
        font.letterSpacing: hud.caps ? 1.6 : 0
        font.capitalization: hud.caps ? Font.AllUppercase : Font.MixedCase
        color: Theme.dim
        verticalAlignment: Text.AlignVCenter
        renderType: Text.NativeRendering
    }
}
