import QtQuick
import "../../shared"
import "../common"

Item {
    id: dd

    property string label
    property var options: []
    property var current
    property bool open: false
    signal picked(var value)

    readonly property int rowH: 34
    readonly property int headH: 46
    readonly property var selected: {
        for (let i = 0; i < options.length; i++)
            if (options[i].v === current) return options[i]
        return null
    }

    implicitHeight: headH + list.height

    Item {
        width: parent.width
        height: dd.headH

        LabelShared {
            anchors.left: parent.left
            anchors.leftMargin: Theme.pad
            anchors.verticalCenter: parent.verticalCenter
            text: dd.label
            font.pixelSize: 13
            color: headArea.containsMouse ? Theme.bright : Theme.fg
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: Theme.pad
            anchors.verticalCenter: parent.verticalCenter
            height: 28
            width: pillRow.implicitWidth + 22
            radius: Theme.r(8)
            color: dd.open ? Theme.soft(Theme.accent) : Theme.alpha(Theme.fg, headArea.containsMouse ? 0.14 : 0.08)
            Behavior on color { ColorAnimation { duration: Theme.fast } }

            Row {
                id: pillRow
                anchors.centerIn: parent
                spacing: 8

                Row {
                    visible: !!dd.selected && !!dd.selected.swatch
                    spacing: 2
                    anchors.verticalCenter: parent.verticalCenter
                    Repeater {
                        model: dd.selected && dd.selected.swatch ? dd.selected.swatch.slice(0, 5) : []
                        Rectangle { required property string modelData; width: 7; height: 12; radius: 2; color: modelData }
                    }
                }

                LabelShared {
                    anchors.verticalCenter: parent.verticalCenter
                    text: dd.selected ? dd.selected.l : "-"
                    font.pixelSize: 12
                    color: dd.open ? Theme.ink : Theme.bright
                }

                LabelShared {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf078"
                    font.pixelSize: 9
                    color: dd.open ? Theme.ink : Theme.fg
                    rotation: dd.open ? 180 : 0
                    Behavior on rotation { NumberAnimation { duration: Theme.ms(220); easing.type: Easing.OutCubic } }
                }
            }
        }

        HoverShared {
            id: headArea
            anchors.fill: parent
            onClicked: dd.open = !dd.open
        }
    }

    Item {
        id: list
        y: dd.headH
        width: parent.width
        height: dd.open ? col.height + 12 : 0
        clip: true
        Behavior on height { NumberAnimation { duration: Theme.ms(240); easing.type: Easing.OutCubic } }

        Column {
            id: col
            width: parent.width - Theme.pad * 2
            x: Theme.pad
            spacing: 2

            Repeater {
                model: dd.options

                Rectangle {
                    required property var modelData
                    readonly property bool on: modelData.v === dd.current
                    width: col.width
                    height: modelData.preview ? dd.rowH + strip.height + 6 : dd.rowH
                    radius: Theme.r(8)
                    color: on ? Theme.soft(Theme.accent) : Theme.alpha(Theme.fg, rowArea.containsMouse ? 0.1 : 0)
                    Behavior on color { ColorAnimation { duration: Theme.ms(120) } }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        y: (dd.rowH - height) / 2
                        spacing: 10

                        Row {
                            visible: !!modelData.swatch
                            spacing: 2
                            anchors.verticalCenter: parent.verticalCenter
                            Repeater {
                                model: modelData.swatch || []
                                Rectangle { required property string modelData; width: 9; height: 14; radius: 3; color: modelData }
                            }
                        }

                        Rectangle {
                            visible: !!modelData.image
                            width: 24
                            height: 24
                            radius: Theme.r(6)
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.alpha(Theme.fg, 0.12)
                            clip: true
                            Image {
                                anchors.fill: parent
                                source: modelData.image || ""
                                sourceSize.width: 48
                                sourceSize.height: 48
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }

                        LabelShared {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.l
                            font.pixelSize: 13
                            color: on ? Theme.ink : rowArea.containsMouse ? Theme.bright : Theme.fg
                        }
                    }

                    Image {
                        id: strip
                        visible: !!modelData.preview
                        x: 12
                        y: dd.rowH - 4
                        width: parent.width - 24
                        height: visible ? width * 70 / 2000 : 0
                        source: modelData.preview || ""
                        sourceSize.width: 1000
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        opacity: on || rowArea.containsMouse ? 0.95 : 0.6
                        Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                    }

                    LabelShared {
                        visible: on
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        y: (dd.rowH - height) / 2
                        text: "\uf00c"
                        font.pixelSize: 11
                        color: Theme.ink
                    }

                    HoverShared {
                        id: rowArea
                        anchors.fill: parent
                        onClicked: { dd.picked(modelData.v); dd.open = false }
                    }
                }
            }
        }
    }
}
