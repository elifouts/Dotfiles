import QtQuick
import Quickshell
import Quickshell.Io
import "../../../shared"
import "../../common"

Column {
    id: menu

    property bool open: false
    signal run(string cmd)
    signal done()

    spacing: 12

    property bool standalone: false
    property string armed: ""
    property string uptime: ""
    onOpenChanged: { armed = ""; if (open) { up.running = true; BrightnessShared.probe() } }

    WatchedShared {
        id: dndFile
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/home-dnd"
    }
    readonly property bool dnd: dndFile.text().trim() === "1"

    Process {
        id: up
        command: ["uptime", "-p"]
        stdout: StdioCollector { onStreamFinished: menu.uptime = text.trim().replace(/^up /, "") }
    }
    Timer { id: disarm; interval: 3000; onTriggered: menu.armed = "" }

    readonly property var actions: [
        { id: "lock", glyph: "", label: "Lock" },
        { id: "suspend", glyph: "󰒲", label: "Suspend" },
        { id: "logout", glyph: "󰍃", label: "Log out" },
        { id: "reboot", glyph: "󰜉", label: "Reboot" },
        { id: "poweroff", glyph: "󰐥", label: "Shut down" }
    ]

    function press(a) {
        if (PowerShared.confirm(a.id) && armed !== a.id) { armed = a.id; disarm.restart(); return }
        armed = ""
        done()
        PowerShared.act(a.id)
    }

    Header {
        title: "Session"
        note: menu.uptime !== "" ? "Up " + menu.uptime : ""
    }

    Row {
        id: grid
        spacing: 6
        readonly property real cell: (menu.width - spacing * (menu.actions.length - 1)) / menu.actions.length

        Repeater {
            model: menu.actions

            Rectangle {
                id: btn
                required property var modelData
                readonly property bool armed: menu.armed === modelData.id
                width: grid.cell
                height: grid.cell + 14
                radius: Math.min(Theme.rounding, 12)
                color: armed ? Theme.soft(Theme.warn)
                    : Theme.alpha(Theme.fg, area.containsMouse ? 0.12 : 0.055)
                scale: area.pressed ? 0.95 : 1
                Behavior on color { ColorAnimation { duration: Theme.fast } }
                Behavior on scale { NumberAnimation { duration: Theme.ms(120) } }

                Column {
                    anchors.centerIn: parent
                    spacing: 6
                    LabelShared {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: btn.modelData.glyph
                        font.pixelSize: 20
                        color: btn.armed ? Theme.on(Theme.warn) : area.containsMouse ? Theme.accent : Theme.fg
                    }
                    LabelShared {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: btn.armed ? "Again" : btn.modelData.label
                        font.pixelSize: 10
                        color: btn.armed ? Theme.on(Theme.warn) : Theme.dim
                    }
                }

                HoverShared {
                    id: area
                    anchors.fill: parent
                    onClicked: menu.press(btn.modelData)
                }
            }
        }
    }

    Tile {
        id: bat
        readonly property var dev: PowerShared.battery
        readonly property bool present: PowerShared.hasBattery
        readonly property real charge: PowerShared.charge
        readonly property bool charging: PowerShared.charging
        readonly property bool full: PowerShared.full
        readonly property bool low: !charging && !full && charge < 0.2
        readonly property real secs: !present ? 0 : charging ? dev.timeToFull : dev.timeToEmpty

        function span(s) {
            const m = Math.round(s / 60)
            return m < 60 ? m + "m" : Math.floor(m / 60) + "h " + (m % 60) + "m"
        }

        visible: present
        width: parent.width
        height: 44

        LabelShared {
            id: batGlyph
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            width: 18
            text: bat.charging || bat.full ? "󰂄" : ["󰁻", "󰁼", "󰁾", "󰂀", "󰂂", "󰁹"][Math.min(5, Math.floor(bat.charge * 6))]
            font.pixelSize: 16
            color: bat.low ? Theme.warn : Theme.bright
        }

        Rectangle {
            anchors.left: batGlyph.right
            anchors.leftMargin: 12
            anchors.right: batTime.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            height: 4
            radius: 2
            color: Theme.alpha(Theme.fg, 0.16)

            Rectangle {
                width: Math.max(parent.height, parent.width * bat.charge)
                height: parent.height
                radius: parent.radius
                color: bat.low ? Theme.warn : Theme.ok
                Behavior on width { NumberAnimation { duration: Theme.move; easing.type: Easing.OutCubic } }
            }
        }

        LabelShared {
            id: batTime
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(bat.charge * 100) + "%" + (bat.full || bat.secs <= 0 ? "" : "  ·  " + bat.span(bat.secs) + (bat.charging ? " to full" : " left"))
            font.pixelSize: 12
            color: Theme.fg
        }
    }

    Tile {
        visible: BrightnessShared.has
        width: parent.width
        height: 44

        LabelShared {
            id: sun
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            width: 18
            text: "󰃠"
            font.pixelSize: 16
            color: Theme.bright
        }
        Slider {
            anchors.left: sun.right
            anchors.leftMargin: 12
            anchors.right: sunPct.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            value: BrightnessShared.value
            onMoved: v => BrightnessShared.set(Math.max(0.01, v))
        }
        LabelShared {
            id: sunPct
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            width: 32
            horizontalAlignment: Text.AlignRight
            text: Math.round(BrightnessShared.value * 100) + "%"
            font.pixelSize: 12
            color: Theme.fg
        }
    }

    Tile {
        visible: !menu.standalone
        width: parent.width
        height: 44

        LabelShared {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: (menu.dnd ? "󰂛" : "󰂚") + "  Do not disturb"
            font.pixelSize: 12
            color: menu.dnd ? Theme.accent2 : Theme.fg
        }
        Switch {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            checked: menu.dnd
            onToggled: menu.run(HyprShared.util + "/session/shells.sh notifications toggleDnd")
        }
    }
}
