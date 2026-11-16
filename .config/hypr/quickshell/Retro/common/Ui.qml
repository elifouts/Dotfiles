pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    property bool bar: true
    property bool touring: false
    property string sheet: "core"
    property var target: null
    property string panel: ""
    property var panelScreen: null
    property string tab: ""
    property var owner: null
    property real ax: 0
    signal request(string what)
    readonly property string host: hostFile.text().trim() || "sys"
    FileView { id: hostFile; path: "/etc/hostname" }

    function openPanel(kind, screen, t) {
        if (kind === "home") return request("home")
        t = t ?? ""
        if (panel === kind && panelScreen === screen && tab === t) return panel = ""
        owner = null
        panelScreen = screen
        tab = t
        panel = kind
    }
}
