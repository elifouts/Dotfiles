import QtQuick
import "../../shared"
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
    readonly property bool holdOpen: captureTab.sharing && current === "capture"
    onCurrentChanged: if (current === "weather") ctx.weather.refresh(false)

    implicitHeight: 196

    Item {
        anchors.fill: parent

        Item {
            x: 50
            width: parent.width - 50
            height: parent.height

            FadeShared {
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
            FadeShared {
                on: page.current === "timer"
                TimerTabShared {
                    anchors.fill: parent
                    timer: page.ctx.timer
                }
            }
            FadeShared {
                on: page.current === "color"
                ColorTabShared {
                    anchors.fill: parent
                    onDone: page.pill.close()
                }
            }
            FadeShared {
                on: page.current === "capture"
                CaptureTabShared {
                    id: captureTab
                    anchors.fill: parent
                    active: page.pill.open && parent.visible
                    open: page.pill.open
                    onDone: page.pill.close()
                }
            }
            FadeShared {
                on: page.current === "weather"
                WeatherTabShared {
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

                    LabelShared {
                        anchors.centerIn: parent
                        text: tab.modelData.glyph
                        font.pixelSize: 14
                        color: tab.on ? Theme.ink : tabArea.containsMouse ? Theme.bright : Theme.fg
                    }

                    HoverShared {
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
