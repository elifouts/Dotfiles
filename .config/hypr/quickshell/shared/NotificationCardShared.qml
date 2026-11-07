import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "../style/common"

Item {
    id: card

    required property var n
    property real u: 1
    property bool popup: false
    property bool expanded: false
    property real progress: -1

    readonly property bool hovered: area.containsMouse || closeArea.containsMouse
    readonly property bool critical: n?.urgency === NotificationUrgency.Critical
    readonly property string iconSrc: n ? NotifsShared.iconFor(n) : ""
    readonly property real pad: (popup ? 14 : 10) * u
    readonly property real iconSize: (popup ? 40 : 36) * u
    readonly property var defaultAction: {
        for (let i = 0; i < (n?.actions.length ?? 0); i++)
            if (n.actions[i].identifier === "default") return n.actions[i]
        return null
    }
    readonly property var extraActions: {
        const out = []
        for (let i = 0; i < (n?.actions.length ?? 0); i++)
            if (n.actions[i].identifier !== "default") out.push(n.actions[i])
        return out
    }

    height: Math.max(iconSize, col.implicitHeight) + pad * 2 + (progress >= 0 ? 4 * u : 0)

    function activate() {
        if (defaultAction) {
            defaultAction.invoke()
            if (popup) NotifsShared.hidePopup(n)
        } else if (popup) NotifsShared.hidePopup(n)
        else expanded = !expanded
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.rounding
        color: card.popup ? Theme.back(0.86) : (area.containsMouse ? "#26ffffff" : "#14ffffff")
        border.width: card.popup || card.critical ? 1 : 0
        border.color: Qt.alpha(card.critical ? Theme.warn : Theme.accent, card.critical ? 0.7 : 0.4)
        Behavior on color { ColorAnimation { duration: Theme.ms(150) } }
        layer.enabled: card.popup
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.4
            shadowBlur: 1
            shadowVerticalOffset: 8 * card.u
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) card.activate()
            else if (card.popup) NotifsShared.hidePopup(card.n)
            else card.n.dismiss()
        }
    }

    ClippingRectangle {
        x: card.pad
        y: card.pad
        width: card.iconSize
        height: card.iconSize
        radius: Theme.rounding * card.u
        color: "#22ffffff"

        Image {
            anchors.fill: parent
            anchors.margins: card.n?.image !== "" ? 0 : 6 * card.u
            visible: card.iconSrc !== ""
            source: card.iconSrc
            sourceSize.width: 96
            sourceSize.height: 96
            fillMode: card.n?.image !== "" ? Image.PreserveAspectCrop : Image.PreserveAspectFit
            asynchronous: true
        }
        LabelShared {
            anchors.centerIn: parent
            visible: card.iconSrc === ""
            text: card.critical ? "\uf071" : "\uf0f3"
            font.pixelSize: card.iconSize * 0.45
            color: card.critical ? Theme.warn : Theme.accent
        }
    }

    SystemClock { id: clock; precision: SystemClock.Minutes; enabled: card.visible }

    Column {
        id: col
        x: card.pad + card.iconSize + 12 * card.u
        y: card.pad
        width: card.width - x - card.pad - 14 * card.u
        spacing: 3 * card.u

        LabelShared {
            width: parent.width
            text: card.n?.summary ?? ""
            elide: Text.ElideRight
            font.pixelSize: (card.popup ? 14 : 13) * card.u
            font.weight: Font.DemiBold
            color: "#ffffff"
        }
        LabelShared {
            width: parent.width
            visible: text !== ""
            text: card.n?.body ?? ""
            textFormat: Text.StyledText
            wrapMode: Text.Wrap
            maximumLineCount: card.expanded ? 14 : (card.popup ? 3 : 2)
            elide: Text.ElideRight
            font.pixelSize: (card.popup ? 12.5 : 12) * card.u
            color: "#cfffffff"
        }
        LabelShared {
            width: parent.width
            text: card.n ? (card.n.appName !== "" ? card.n.appName + "  ·  " : "") + NotifsShared.ago(card.n, clock.date) : ""
            elide: Text.ElideRight
            font.pixelSize: 10.5 * card.u
            color: "#66ffffff"
        }
        Flow {
            width: parent.width
            visible: card.extraActions.length > 0
            topPadding: 5 * card.u
            spacing: 6 * card.u
            Repeater {
                model: card.extraActions
                delegate: Item {
                    id: act
                    required property var modelData
                    width: actLabel.implicitWidth + 22 * card.u
                    height: 26 * card.u
                    scale: actArea.pressed ? 0.94 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.ms(140); easing.type: Easing.OutBack } }
                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.round * height / 2
                        color: actArea.containsMouse ? "#40ffffff" : "#26ffffff"
                        Behavior on color { ColorAnimation { duration: Theme.ms(150) } }
                    }
                    LabelShared {
                        id: actLabel
                        anchors.centerIn: parent
                        text: act.modelData.text
                        font.pixelSize: 11 * card.u
                        color: "#ffffff"
                    }
                    MouseArea {
                        id: actArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            act.modelData.invoke()
                            if (card.popup) NotifsShared.hidePopup(card.n)
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        visible: card.progress >= 0
        x: card.pad
        y: card.height - 7 * card.u
        width: (card.width - card.pad * 2) * card.progress
        height: 2 * card.u
        radius: height / 2
        color: card.critical ? Theme.warn : Theme.accent
        opacity: 0.8
    }

    LabelShared {
        x: card.width - card.pad - width + 2 * card.u
        y: card.pad - 2 * card.u
        text: "\uf00d"
        opacity: card.hovered ? 1 : 0
        font.pixelSize: 13 * card.u
        color: closeArea.containsMouse ? "#ffffff" : "#99ffffff"
        Behavior on opacity { NumberAnimation { duration: Theme.ms(150) } }

        MouseArea {
            id: closeArea
            anchors.fill: parent
            anchors.margins: -8 * card.u
            hoverEnabled: true
            onClicked: card.n.dismiss()
        }
    }
}
