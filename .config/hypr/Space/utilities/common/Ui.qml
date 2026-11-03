pragma Singleton

import QtQuick
import Quickshell

// what's open, so the windows can react to each other
Singleton {
    id: root

    property bool bar: true
    property bool overview: false
    // monitor name whose desk is being edited
    property string editing: ""
    // monitor whose desk wants keys (the todo box)
    property string typing: ""
    // "core" or "profiles", picked before the settings sheet loads
    property string sheet: "core"
    // the monitor an overlay opened on, so it stays put
    property var target: null

    // bar panel: which one, on what screen, and the media panel's tab
    property string panel: ""
    property var panelScreen: null
    property string tab: ""
    // anything that isn't a panel goes to the shell, like the scan overlay
    signal request(string what)

    function openPanel(kind, screen, t) {
        if (kind === "scan") return request("scan")
        t = t ?? ""
        if (panel === kind && panelScreen === screen && tab === t) return panel = ""
        panelScreen = screen
        tab = t
        panel = kind
    }
}
