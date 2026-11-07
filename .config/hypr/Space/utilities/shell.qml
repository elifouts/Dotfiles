import QtQuick
import Quickshell
import Quickshell.Io
import "common"
import "bar"
import "bar/panels"
import "desk"
import "land"
import "launcher"
import "scan"
import "settings"
import "starmap"
import "welcome"

ShellRoot {
    id: shell

    Component.onCompleted: StoreShared.refresh()

    Variants {
        model: Quickshell.screens
        Scope {
            id: per
            required property var modelData
            DeskModel { id: dm; screen: per.modelData }
            Land { screen: per.modelData; desk: dm }
            Bar { screen: per.modelData }
            LazyLoader { active: Ui.editing === per.modelData.name; DeskEdit { model: dm } }
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
    Overlay { id: overview; StarMap { onDone: overview.active = false } }
    Overlay { id: scan; Scan { onDone: scan.active = false } }
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
        case "scan": return scan.toggle()
        case "settings": return sheet("core")
        case "colors": return sheet("colors")
        case "motion": return sheet("animations")
        case "desk": return Ui.editing = Ui.editing ? "" : HyprShared.focusedScreen()?.name ?? ""
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
