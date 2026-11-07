import QtQuick
import Quickshell.Widgets
import "../style/common"

Item {
    id: c

    property string url: ""
    property real radius: 12
    property color fill: Theme.alpha(Theme.fg, 0.07)
    property string glyph: ""
    property color glyphColor: Theme.dim
    property int res: 256

    property bool useA: true
    property int dir: 1
    property real p: 1

    onUrlChanged: {
        const front = useA ? imgA : imgB
        const back = useA ? imgB : imgA
        if (url !== "" && front.source == url) return
        if (back.source != url) back.source = url
        swapTo(back)
    }
    function swapTo(img) {
        if ((img === imgA) === useA) return
        dir = (useA ? imgA : imgB).status === Image.Ready ? MediaShared.skipDir() : 0
        useA = img === imgA
        slide.restart()
    }
    Component.onCompleted: imgA.source = url

    NumberAnimation { id: slide; target: c; property: "p"; from: 0; to: 1; duration: Theme.ms(300); easing.type: Easing.OutCubic }

    ClippingRectangle {
        anchors.fill: parent
        radius: c.radius
        color: c.fill

        LabelShared {
            anchors.centerIn: parent
            visible: c.glyph !== ""
            text: c.glyph
            font.pixelSize: Math.round(c.height * 0.3)
            color: c.glyphColor
        }

        CoverImage { id: imgA; front: c.useA }
        CoverImage { id: imgB; front: !c.useA }
    }

    component CoverImage: Image {
        property bool front
        width: c.width
        height: c.height
        x: (front ? 1 - c.p : -c.p) * c.dir * c.width * 0.45
        property real seen: status === Image.Ready ? 1 : 0
        Behavior on seen { NumberAnimation { duration: Theme.ms(180); easing.type: Easing.OutCubic } }
        opacity: seen * (front ? c.p : 1 - c.p)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        mipmap: true
        sourceSize: Qt.size(c.res, c.res)
    }
}
