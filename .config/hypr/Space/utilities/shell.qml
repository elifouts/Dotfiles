import QtQuick
import Quickshell
import Quickshell.Io
import "common"
import "bar"
import "desk"
import "land"
import "launcher"
import "scan"
import "settings"
import "starmap"

ShellRoot {
    id: shell

    Component.onCompleted: Store.refresh()

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

    Osd {}
    NotificationPopups {}
    Binding { target: Media; property: "side"; value: "left" }

    component Overlay: LazyLoader {
        function toggle() {
            if (active) return item?.close()
            Ui.panel = ""
            Ui.target = Hypr.focusedScreen()
            active = true
        }
    }
    Overlay { id: launcher; Launcher { onDone: launcher.active = false } }
    Overlay { id: overview; StarMap { onDone: overview.active = false } }
    Overlay { id: scan; Scan { onDone: scan.active = false } }
    Overlay { id: settings; Settings { onDone: settings.active = false } }

    function sheet(which) {
        if (settings.active && Ui.sheet !== which) { Ui.sheet = which; settings.item.tab = which; return }
        Ui.sheet = which
        settings.toggle()
    }
    function run(what) {
        switch (what) {
        case "launcher": return launcher.toggle()
        case "overview": return overview.toggle()
        case "scan": return scan.toggle()
        case "settings": return sheet("core")
        case "profiles": return sheet("profiles")
        case "colors": return sheet("colors")
        case "motion": return sheet("motion")
        case "desk": return Ui.editing = Ui.editing ? "" : Hypr.focusedScreen()?.name ?? ""
        case "bar": return Ui.bar = !Ui.bar
        case "world": return World.hop()
        case "capture": return Ui.openPanel("media", Hypr.focusedScreen(), "capture")
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
        function act(action: string): void { OsdState.act(action) }
        function brightness(value: real): void { OsdState.brightness(value) }
    }
}
