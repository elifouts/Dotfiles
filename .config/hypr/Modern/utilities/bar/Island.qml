import QtQuick
import Quickshell
import "../common"
import "island"

Item {
    id: page

    property var ctx
    property var pill

    readonly property var tabs: [
        { id: "media", glyph: "󰝚" },
        { id: "timer", glyph: "󰔛" },
        { id: "color", glyph: "󰈊" },
        { id: "capture", glyph: "󰄀" },
        { id: "weather", glyph: ctx.weather.ready ? ctx.weather.glyph(ctx.weather.code, ctx.weather.night) : "󰖕" }
    ]
    readonly property string current: pill.tab !== "" ? pill.tab : "media"
    // keeps the menu up while an app waits on me to pick a share
    readonly property bool holdOpen: captureTab.sharing && current === "capture"
    onCurrentChanged: if (current === "weather") ctx.weather.refresh(false)

    implicitHeight: 196

    Item {
        anchors.fill: parent

        Item {
            x: 50
            width: parent.width - 50
            height: parent.height

            // tabs keep the 440 they were laid out for, centred. media takes the whole width
            component Fade: Item {
                property bool on: false
                property real maxW: 440
                width: Math.min(maxW, parent.width)
                height: parent.height
                x: (parent.width - width) / 2
                opacity: on ? 1 : 0
                visible: opacity > 0
                transform: Translate { y: (1 - opacity) * 6 }
                Behavior on opacity { Settle { duration: Theme.move } }
            }

            Fade {
                on: page.current === "media"
                maxW: Infinity
                MediaTab {
                    anchors.fill: parent
                    active: page.pill.open && parent.visible
                    player: page.ctx.player
                    track: page.ctx.track
                    playerCount: page.ctx.players.length
                    musicOut: page.ctx.mediaAway(page.pill)
                    canPopOut: !page.ctx.standalone
                    onCyclePlayer: page.ctx.cyclePlayer()
                    onPopOut: { page.pill.close(); if (!page.ctx.musicOut) page.ctx.musicCall("open") }
                    onBringBack: { page.pill.close(); page.ctx.musicCall("close") }
                }
            }
            Fade {
                on: page.current === "timer"
                TimerTab {
                    anchors.fill: parent
                    timer: page.ctx.timer
                }
            }
            Fade {
                on: page.current === "color"
                ColorTab {
                    anchors.fill: parent
                    onPick: { page.pill.close(); page.ctx.pickColor() }
                    onCopy: c => page.ctx.run("printf %s '" + c + "' | wl-copy")
                }
            }
            Fade {
                on: page.current === "capture"
                CaptureTab {
                    id: captureTab
                    anchors.fill: parent
                    active: page.pill.open && parent.visible
                    open: page.pill.open
                    onCapture: (kind, mode) => {
                        page.pill.close()
                        page.ctx.run("sleep 0.35; '" + Quickshell.shellDir + "/bar/" + (kind === "share" ? "share.sh' pick " : "capture.sh' " + kind + " ") + mode)
                    }
                    onCancelShare: page.ctx.run("'" + Quickshell.shellDir + "/bar/share.sh' cancel")
                    onCast: (tv, mode) => {
                        page.pill.close()
                        Quickshell.execDetached(["sh", "-c", 'sleep 0.35; exec "$0" start "$1" "$2" "$3" "$4"',
                            Quickshell.shellDir + "/bar/cast.py", tv.kind, tv.target, tv.name, mode])
                    }
                    onStopCast: Quickshell.execDetached([Quickshell.shellDir + "/bar/cast.py", "stop"])
                    onStop: page.ctx.run("'" + Quickshell.shellDir + "/bar/capture.sh' stop")
                }
            }
            Fade {
                on: page.current === "weather"
                WeatherTab {
                    anchors.fill: parent
                    weather: page.ctx.weather
                }
            }
        }

        Column {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Repeater {
                model: page.tabs

                Rectangle {
                    id: tab
                    required property var modelData
                    readonly property bool on: page.current === modelData.id
                    width: 32
                    height: 32
                    radius: Math.min(Theme.rounding, 10)
                    color: on ? Theme.soft(Theme.accent) : Theme.alpha(Theme.fg, tabArea.containsMouse ? 0.1 : 0.04)
                    Behavior on color { ColorAnimation { duration: Theme.fast } }

                    Label {
                        anchors.centerIn: parent
                        text: tab.modelData.glyph
                        font.pixelSize: 14
                        color: tab.on ? Theme.ink : tabArea.containsMouse ? Theme.bright : Theme.fg
                    }

                    Hover {
                        id: tabArea
                        anchors.fill: parent
                        onContainsMouseChanged: if (containsMouse) page.pill.tab = tab.modelData.id
                        onClicked: page.pill.tab = tab.modelData.id
                    }
                }
            }

            WheelHandler {
                onWheel: e => {
                    const i = page.tabs.findIndex(t => t.id === page.current)
                    page.pill.tab = page.tabs[(i + (e.angleDelta.y > 0 ? -1 : 1) + page.tabs.length) % page.tabs.length].id
                }
            }
        }
    }
}
