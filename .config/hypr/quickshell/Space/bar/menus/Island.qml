import QtQuick
import "../../../shared"
import "../../common"

Item {
    id: pm
    width: parent?.width ?? 456
    height: Math.max(strip.height, pages.height)

    readonly property var tabs: [
        { id: "media", glyph: "󰝚" }, { id: "timer", glyph: "󰔛" }, { id: "color", glyph: "󰈊" }, { id: "capture", glyph: "󰄀" },
        { id: "weather", glyph: TimerForecast.weather.ready ? TimerForecast.weather.glyph(TimerForecast.weather.code, TimerForecast.weather.night) : "󰖕" }
    ]
    readonly property string current: Ui.tab || "media"
    readonly property bool holdOpen: cap.sharing && current === "capture"
    onCurrentChanged: if (current === "weather") TimerForecast.weather.refresh(false)

    Item {
        id: pages
        width: parent.width - 44
        height: Math.max(150, media.implicitHeight)

        FadeShared { on: pm.current === "media"; maxW: Infinity; MediaCard { id: media; width: parent.width } }
        FadeShared { on: pm.current === "timer"; TimerTabShared { anchors.fill: parent; timer: TimerForecast.timer } }
        FadeShared { on: pm.current === "color"; ColorTabShared { anchors.fill: parent; onDone: Ui.panel = "" } }
        FadeShared {
            on: pm.current === "capture"
            CaptureTabShared { id: cap; anchors.fill: parent; active: parent.visible; open: Ui.panel === "media"; onDone: Ui.panel = "" }
        }
        FadeShared { on: pm.current === "weather"; WeatherTabShared { anchors.fill: parent; weather: TimerForecast.weather } }
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
                HoverShared { id: tabArea; anchors.fill: parent; onContainsMouseChanged: if (containsMouse) Ui.tab = tab.modelData.id }
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
