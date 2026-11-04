import QtQuick
import "../common"
import "../media"

Item {
    id: pm
    width: parent?.width ?? 456
    height: Math.max(strip.height, pages.height)

    readonly property var tabs: [
        { id: "media", glyph: "󰝚" }, { id: "timer", glyph: "󰔛" }, { id: "color", glyph: "󰈊" }, { id: "capture", glyph: "󰄀" },
        { id: "weather", glyph: Live.weather.ready ? Live.weather.glyph(Live.weather.code, Live.weather.night) : "󰖕" }
    ]
    readonly property string current: Ui.tab || "media"
    readonly property bool holdOpen: cap.sharing && current === "capture"
    onCurrentChanged: if (current === "weather") Live.weather.refresh(false)

    Item {
        id: pages
        width: parent.width - 44
        height: Math.max(150, media.implicitHeight)

        Fade { on: pm.current === "media"; maxW: Infinity; MediaCtl { id: media; width: parent.width } }
        Fade { on: pm.current === "timer"; TimerTab { anchors.fill: parent; timer: Live.timer } }
        Fade { on: pm.current === "color"; ColorTab { anchors.fill: parent; onDone: Ui.panel = "" } }
        Fade {
            on: pm.current === "capture"
            CaptureTab { id: cap; anchors.fill: parent; active: parent.visible; open: Ui.panel === "media"; onDone: Ui.panel = "" }
        }
        Fade { on: pm.current === "weather"; WeatherTab { anchors.fill: parent; weather: Live.weather } }
    }

    Column {
        id: strip
        anchors.right: parent.right
        anchors.verticalCenter: pages.verticalCenter
        spacing: 4
        Repeater {
            model: pm.tabs
            Item {
                id: tab
                required property var modelData
                readonly property bool on: pm.current === modelData.id
                width: 30
                height: 30
                Rectangle { width: 2; height: parent.height; color: Theme.accent; visible: tab.on }
                Text {
                    anchors.fill: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: tab.modelData.glyph
                    font.family: Theme.font
                    font.pixelSize: 15
                    color: tab.on ? Theme.accent : tabArea.containsMouse ? Theme.fg : Theme.dim
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                }
                Hover { id: tabArea; anchors.fill: parent; onContainsMouseChanged: if (containsMouse) Ui.tab = tab.modelData.id }
            }
        }
        WheelHandler {
            onWheel: e => {
                const i = pm.tabs.findIndex(t => t.id === pm.current)
                Ui.tab = pm.tabs[(i + (e.angleDelta.y > 0 ? -1 : 1) + pm.tabs.length) % pm.tabs.length].id
            }
        }
    }
}
