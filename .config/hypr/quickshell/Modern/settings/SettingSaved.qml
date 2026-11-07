import QtQuick
import "../../shared"
import "../common"

Item {
    id: control

    property var def
    readonly property var entries: StoreShared.saved.entries || []
    readonly property string draft: input.text.trim()
    readonly property bool exists: entries.some(e => e.kind === "saved" && e.name.toLowerCase() === draft.toLowerCase())
    property string armed: ""

    implicitHeight: col.height

    Timer { id: disarm; interval: 2500; onTriggered: control.armed = "" }

    function arm(id) {
        if (armed === id) return true
        armed = id
        disarm.restart()
        return false
    }

    function submit() {
        if (!draft) return
        StoreShared.savedRun("save", draft)
        input.text = ""
        release()
    }

    function release() {
        let p = input.parent
        while (p && p.objectName !== "keyRoot") p = p.parent
        if (p) p.forceActiveFocus()
    }

    Column {
        id: col
        width: parent.width

        Repeater {
            model: control.entries

            Item {
                id: entry
                required property var modelData
                required property int index
                readonly property bool current: modelData.id === StoreShared.saved.active
                readonly property bool usable: modelData.exists
                readonly property bool deletable: modelData.kind !== "default" && modelData.exists
                readonly property bool hot: rowArea.containsMouse || binArea.containsMouse

                width: col.width
                height: 46
                opacity: usable || current ? 1 : 0.5

                Rectangle {
                    visible: entry.index > 0
                    x: Theme.pad
                    width: parent.width - Theme.pad * 2
                    height: 1
                    color: Theme.alpha(Theme.fg, 0.07)
                }

                HoverShared {
                    id: rowArea
                    anchors.fill: parent
                    enabled: entry.usable && !entry.current
                    onClicked: StoreShared.savedRun("apply", entry.modelData.id)
                }

                Rectangle {
                    id: dot
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.pad
                    anchors.verticalCenter: parent.verticalCenter
                    width: 8
                    height: 8
                    radius: 4
                    color: entry.current ? Theme.accent : Theme.alpha(Theme.fg, 0.2)
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                }

                LabelShared {
                    id: label
                    anchors.left: dot.right
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, tag.x - x - kind.implicitWidth - 18)
                    text: entry.modelData.name
                    elide: Text.ElideRight
                    font.pixelSize: 13
                    color: entry.current || entry.hot ? Theme.bright : Theme.fg
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                }

                LabelShared {
                    id: kind
                    anchors.left: label.right
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: entry.modelData.kind === "default" ? "no overrides"
                        : entry.modelData.kind === "variant" ? (entry.modelData.exists ? "variant tweaks" : "no tweaks yet")
                        : ""
                    font.pixelSize: 10
                    color: Theme.dim
                }

                LabelShared {
                    id: tag
                    anchors.right: bin.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: entry.current ? "Applied" : rowArea.containsMouse ? "Apply" : ""
                    font.pixelSize: 11
                    color: entry.current ? Theme.accent : Theme.dim
                }

                Rectangle {
                    id: bin
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.pad - 4
                    anchors.verticalCenter: parent.verticalCenter
                    readonly property bool primed: control.armed === "del:" + entry.modelData.id
                    visible: entry.deletable
                    width: primed ? binText.implicitWidth + 18 : 28
                    height: 28
                    radius: Theme.r(8)
                    color: primed ? Theme.soft(Theme.warn) : Theme.alpha(Theme.fg, binArea.containsMouse ? 0.14 : 0)
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                    Behavior on width { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }

                    LabelShared {
                        id: binText
                        anchors.centerIn: parent
                        text: bin.primed ? "Delete?" : ""
                        font.pixelSize: bin.primed ? 11 : 13
                        color: bin.primed ? Theme.on(Theme.warn) : binArea.containsMouse ? Theme.bright : Theme.dim
                    }

                    HoverShared {
                        id: binArea
                        anchors.fill: parent
                        onClicked: if (control.arm("del:" + entry.modelData.id)) {
                            control.armed = ""
                            StoreShared.savedRun("delete", entry.modelData.id)
                        }
                    }
                }

                Item { visible: !entry.deletable; anchors.right: parent.right; width: Theme.pad + 24; height: 1 }
            }
        }

        Rectangle {
            x: Theme.pad
            width: parent.width - Theme.pad * 2
            height: 1
            color: Theme.alpha(Theme.fg, 0.07)
        }

        Item {
            width: parent.width
            height: 52

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: Theme.pad - 4
                anchors.right: saveBtn.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                height: 32
                radius: Theme.r(8)
                color: Theme.alpha(Theme.fg, input.activeFocus ? 0.12 : 0.07)
                border.width: input.activeFocus ? 1 : 0
                border.color: Theme.alpha(Theme.accent, 0.6)
                Behavior on color { ColorAnimation { duration: Theme.fast } }

                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    maximumLength: 40
                    validator: RegularExpressionValidator { regularExpression: /[A-Za-z0-9 _-]*/ }
                    font.family: Theme.sans
                    font.pixelSize: 12
                    color: Theme.bright
                    selectionColor: Theme.alpha(Theme.accent, 0.5)
                    selectedTextColor: Theme.bright
                    onAccepted: control.submit()
                    Keys.onEscapePressed: { text = ""; control.release() }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !input.text && !input.activeFocus
                        text: "New profile name"
                        font: input.font
                        color: Theme.dim
                    }
                }
            }

            Rectangle {
                id: saveBtn
                anchors.right: parent.right
                anchors.rightMargin: Theme.pad
                anchors.verticalCenter: parent.verticalCenter
                width: saveText.implicitWidth + 22
                height: 32
                radius: Theme.r(8)
                opacity: control.draft ? 1 : 0.4
                color: Theme.soft(Theme.accent, saveArea.containsMouse && control.draft)
                Behavior on color { ColorAnimation { duration: Theme.fast } }

                LabelShared {
                    id: saveText
                    anchors.centerIn: parent
                    text: control.exists ? "Overwrite" : "Save"
                    font.pixelSize: 12
                    color: Theme.ink
                }

                HoverShared {
                    id: saveArea
                    anchors.fill: parent
                    enabled: !!control.draft
                    onClicked: control.submit()
                }
            }
        }

        Item {
            width: parent.width
            height: 52
            readonly property bool primed: control.armed === "wipe"

            Rectangle {
                anchors.fill: parent
                anchors.margins: 9
                radius: Theme.r(8)
                color: parent.primed ? Theme.soft(Theme.warn) : Theme.alpha(Theme.fg, wipeArea.containsMouse ? 0.14 : 0.07)
                Behavior on color { ColorAnimation { duration: Theme.fast } }

                LabelShared {
                    anchors.centerIn: parent
                    text: parent.parent.primed ? "Click again to delete everything" : "Delete all saved profiles and tweaks"
                    font.pixelSize: 12
                    color: parent.parent.primed ? Theme.on(Theme.warn) : wipeArea.containsMouse ? Theme.bright : Theme.fg
                }

                HoverShared {
                    id: wipeArea
                    anchors.fill: parent
                    onClicked: if (control.arm("wipe")) {
                        control.armed = ""
                        StoreShared.savedRun("wipe")
                    }
                }
            }
        }
    }
}
