import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../common"
import "../desk"

PanelWindow {
    id: win

    required property var desk
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "black"
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "space-wall"
    WlrLayershell.keyboardFocus: Ui.typing === screen?.name ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property int ws: Hyprland.focusedWorkspace?.id ?? 1
    readonly property bool moving: World.hopBusy || panning.running

    Connections {
        target: land.Window.window
        enabled: win.moving && win.screen === Hypr.moonScreen
        function onFrameSwapped() { Pace.frame() }
    }

    Terrain {
        id: land
        anchors.fill: parent
        ws: win.ws
        screenX: win.screen?.x ?? 0
        asTheme: true
        moonless: win.screen === Hypr.moonScreen ? 0 : 1
        fade: World.hopBusy || Ui.overview ? 0 : Theme.ms(900)
        drift: World.hopBusy ? World.hopTravel - (World.hopSwapped ? 1.2 : 0) : 0
        lift: World.hopBusy && World.hopSwapped ? 0.9 * Math.pow(1 - World.hopAfter, 3) : 0
        skyFade: !World.hopBusy ? 1 : World.hopSwapped ? World.ease(World.hopAfter) : 1 - World.ease(World.hopProg / 0.3)
        layer.enabled: true
        layer.textureSize: win.moving ? Pace.size(width, height, win.screen) : Qt.size(0, 0)
        Behavior on pan { enabled: !World.hopBusy; NumberAnimation { id: panning; duration: Theme.ms(1400); easing.type: Easing.InOutCubic } }
    }
    Terrain {
        id: before
        anchors.fill: parent
        visible: World.hopBusy
        ws: win.ws
        screenX: land.screenX
        moonless: land.moonless
        drift: World.hopTravel
        lift: -0.9 * (1 - Math.cos(Math.PI / 2 * Math.min(1, World.hopProg / 0.5)))
        skyFade: 1 - World.ease(World.hopProg / 0.5)
        wipe: World.ease(World.hopAfter)
        layer.enabled: visible && Pace.scale < 1
        layer.textureSize: Pace.size(width, height, win.screen)
    }

    Connections {
        target: World
        function onHopped() {
            before.seed = land.seed
            before.bg = land.bg
            before.accent = land.accent
            before.fg = land.fg
            before.tone = land.tone
        }
    }

    Desk { anchors.fill: parent; model: win.desk; visible: Ui.editing !== win.screen?.name }
}
