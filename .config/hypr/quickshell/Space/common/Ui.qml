pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool bar: true
    property bool overview: false
    property bool covered: false
    property bool holdTheme: false
    property bool touring: false
    property string sheet: "core"
    property var target: null

    property string panel: ""
    property var panelScreen: null
    property string tab: ""
    signal request(string what)

    function openPanel(kind, screen, t) {
        if (kind === "home") return request("home")
        t = t ?? ""
        if (panel === kind && panelScreen === screen && tab === t) return panel = ""
        panelScreen = screen
        tab = t
        panel = kind
    }
}
