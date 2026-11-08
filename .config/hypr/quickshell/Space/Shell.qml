import QtQuick
import Quickshell
import Quickshell.Io
import "../shared"
import "common"
import "bar"
import "bar/menus"
import "wallpaper"
import "launcher"
import "home"
import "settings"
import "overview"
import "welcome"

ShellRoot {
    id: shell

    Component.onCompleted: StoreShared.refresh()

    Variants {
        model: Quickshell.screens
        Scope {
            id: per
            required property var modelData
            WidgetModelShared { id: dm; screen: per.modelData; style: "space" }
            Wallpaper { screen: per.modelData; widgets: dm }
            Bar { screen: per.modelData }
            LazyLoader { active: WidgetStateShared.editing === per.modelData.name; WidgetsEditShared { model: dm } }
        }
    }

    OsdShared {}
    NotificationPopupsShared {}
    Binding { target: MediaShared; property: "side"; value: "left" }

    component Overlay: LazyLoader {
        function toggle(scr) {
            if (active) return item?.toggle ? item.toggle() : item?.close()
            Ui.panel = ""
            Ui.target = scr ?? HyprShared.focusedScreen()
            active = true
        }
    }
    Overlay { id: launcher; Launcher { onDone: launcher.active = false } }
    Overlay { id: overview; Overview { onDone: overview.active = false } }
    Overlay { id: home; Home { onDone: home.active = false } }
    Overlay { id: settings; Settings { onDone: settings.active = false } }
    Welcome {
        id: tour
        landing: overview.active
        onPanel: (name, call) => {
            const o = ({ settings: settings, launcher: launcher, overview: overview })[name]
            if (o && o.active !== (call === "open")) o.toggle(tour.screen)
        }
        onPeek: page => { if (Ui.sheet !== page) shell.sheet(page) }
    }

    function sheet(which) {
        if (settings.active && Ui.sheet !== which) { Ui.sheet = which; settings.item.tab = which; settings.item.open(); return }
        Ui.sheet = which
        settings.toggle()
    }
    function run(what) {
        switch (what) {
        case "launcher": return launcher.toggle()
        case "overview": return overview.toggle()
        case "home": return home.toggle()
        case "settings": return sheet("core")
        case "colors": return sheet("colors")
        case "motion": return sheet("animations")
        case "widgets": return WidgetStateShared.toggle()
        case "bar": return Ui.bar = !Ui.bar
        case "world": return World.hop()
        case "capture": return Ui.openPanel("media", HyprShared.focusedScreen(), "capture")
        }
    }
    Connections { target: Ui; function onRequest(what) { shell.run(what) } }

    IpcHandler {
        target: "space"
        function toggle(what: string): void { shell.run(what) }
        function open(what: string): void { shell.run(what) }
    }
    IpcHandler {
        target: "osd"
        function act(action: string): void { OsdStateShared.act(action) }
        function brightness(value: real): void { OsdStateShared.brightness(value) }
    }
}
