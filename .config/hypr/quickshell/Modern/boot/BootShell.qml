import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../shared"
import "../common"

ShellRoot {
    id: root

    readonly property var sourceLabels: [
        "hypr/startup.lua",
        "hypr/shortcuts.lua",
        "hypr/style.lua",
        "waybar/config",
        "boot/BootShell.qml"
    ]
    readonly property var sourceTexts: [
        configFile.text(),
        modernConfigFile.text(),
        styleFile.text(),
        waybarFile.text(),
        bootFile.text()
    ]
    readonly property int sourceIndex: Math.floor(Math.random() * sourceLabels.length)
    readonly property int lowerSourceIndex: (sourceIndex + 1) % sourceLabels.length
    readonly property string sourceLabel: sourceLabels[sourceIndex]
    readonly property var logs: [
        "wayland compositor handshake",
        "display pipeline calibrated",
        "session services restored",
        "input surfaces registered",
        "wallpaper shader compiled",
        "desktop surface available"
    ]
    readonly property var codeLines: {
        var source = (sourceTexts[sourceIndex] || "").trim()
        if (source === "") {
            return [
                "hl.on(\"hyprland.start\", function()",
                "    hl.exec_cmd(\"waybar\")",
                "    hl.exec_cmd(\"qs -p utilities/home\")",
                "    hl.exec_cmd(\"awww restore\")",
                "end)"
            ]
        }
        return source.split("\n").filter(function(line) {
            return line.trim() !== ""
        }).slice(0, 30)
    }
    readonly property var lowerCodeLines: {
        var source = (sourceTexts[lowerSourceIndex] || "").trim()
        if (source === "") {
            return codeLines
        }
        return source.split("\n").filter(function(line) {
            return line.trim() !== ""
        }).slice(0, 18)
    }

    readonly property int blackMs: {
        var v = parseInt(Quickshell.env("BOOT_BLACK_MS"))
        return isNaN(v) || v < 0 ? 2500 : v
    }

    property real reveal: 0
    property real boot: 0
    property real exit: 0
    property int logIndex: 0
    property int codeLineIndex: 0
    property int codeChars: 0
    property bool codeComplete: false
    property int lowerCodeLineIndex: 0
    property int lowerCodeChars: 0
    property bool lowerCodeComplete: false
    property bool shown: true
    property bool closing: false
    property bool sequenceStarted: false
    property date now: new Date()
    readonly property real closeT: 1 - exit
    readonly property real closeOpacity: Math.max(0.001, Math.min(1, closeT * 2.5))

    WatchedShared { id: wallFile; path: HyprShared.home + "/.cache/wal/wal" }
    WatchedShared { id: configFile; path: Quickshell.shellPath("../base/startup.lua") }
    WatchedShared { id: modernConfigFile; path: Quickshell.shellPath("../base/shortcuts.lua") }
    WatchedShared { id: styleFile; path: Quickshell.shellPath("../base/style.lua") }
    WatchedShared { id: waybarFile; path: HyprShared.home + "/.config/waybar/config" }
    WatchedShared { id: bootFile; path: Quickshell.shellPath("boot/BootShell.qml") }

    readonly property string wallPath: wallFile.text().trim()
    function phase(start, length) {
        return Math.max(0, Math.min(1, (boot - start) / length))
    }

    Timer {
        interval: root.blackMs
        running: true
        onTriggered: {
            root.sequenceStarted = true
            bootAnimation.start()
            revealAnimation.start()
        }
    }

    Timer {
        interval: 420
        repeat: true
        running: root.sequenceStarted
        onTriggered: root.logIndex = (root.logIndex + 1) % root.logs.length
    }

    Timer {
        interval: 18
        repeat: true
        running: root.sequenceStarted
        onTriggered: {
            if (root.codeComplete) {
                return
            }
            var line = root.codeLines[root.codeLineIndex] || ""
            root.codeChars += 14
            if (root.codeChars > line.length + 10) {
                if (root.codeLineIndex === root.codeLines.length - 1) {
                    root.codeChars = line.length
                    root.codeComplete = true
                } else {
                    root.codeLineIndex += 1
                    root.codeChars = 0
                }
            }
        }
    }

    Timer {
        interval: 14
        repeat: true
        running: root.sequenceStarted
        onTriggered: {
            if (root.lowerCodeComplete) {
                return
            }
            var line = root.lowerCodeLines[root.lowerCodeLineIndex] || ""
            root.lowerCodeChars += 18
            if (root.lowerCodeChars > line.length + 10) {
                if (root.lowerCodeLineIndex === root.lowerCodeLines.length - 1) {
                    root.lowerCodeChars = line.length
                    root.lowerCodeComplete = true
                } else {
                    root.lowerCodeLineIndex += 1
                    root.lowerCodeChars = 0
                }
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.now = new Date()
    }

    NumberAnimation {
        id: bootAnimation
        target: root
        property: "boot"
        from: 0
        to: 1
        duration: 1200
        easing.type: Easing.OutCubic
        onFinished: root.close()
    }

    NumberAnimation {
        id: revealAnimation
        target: root
        property: "reveal"
        from: 0
        to: 1
        duration: 1150
        easing.type: Easing.InOutCubic
    }

    function close() {
        if (closing) {
            return
        }
        closing = true
        exitAnimation.start()
    }

    NumberAnimation {
        id: exitAnimation
        target: root
        property: "exit"
        from: 0
        to: 1
        duration: 450
        easing.type: Easing.InOutCubic
        onFinished: {
            root.shown = false
            Qt.callLater(() => finishTimer.start())
        }
    }

    Timer {
        id: finishTimer
        interval: 250
        onTriggered: Qt.quit()
    }

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.shown
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "boot-sequence"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Backdrop {
                anchors.fill: parent
                opacity: root.reveal * root.closeOpacity
                zoom: 0.035 * root.closeT + 0.025 * (1 - root.reveal) * root.closeT
                dim: 0.22 * root.closeT
                source: root.wallPath === "" ? "" : "file://" + root.wallPath
            }

            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: 1 - root.reveal
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.bg
                opacity: 0.16 * root.closeT
            }

            Item {
                anchors.fill: parent
                opacity: root.closeOpacity * Math.min(1, root.boot * 1.8)

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height) * 0.42
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.alpha(Theme.info, 0.16)
                    rotation: root.boot * 18
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height) * 0.29
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.alpha(Theme.accent2, 0.26)
                    rotation: -root.boot * 28
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height) * 0.16
                    height: width
                    radius: width / 2
                    color: Theme.alpha(Theme.accent, 0.08)
                    border.width: 1
                    border.color: Theme.accent
                    scale: 0.8 + root.phase(0.2, 0.65) * 0.2
                }

                Text {
                    anchors.centerIn: parent
                    text: "HYPRLAND"
                    color: Theme.bright
                    font.family: Theme.sans
                    font.pixelSize: Math.max(18, Math.min(parent.width, parent.height) * 0.022)
                    font.letterSpacing: 5
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height / 2 + Math.min(parent.width, parent.height) * 0.09
                    text: "SESSION / " + (root.boot < 0.82 ? "INITIALIZING" : "READY")
                    color: root.boot < 0.82 ? Theme.accent : Theme.ok
                    font.family: Theme.sans
                    font.pixelSize: 11
                    font.letterSpacing: 2
                }
            }

            Column {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.leftMargin: 56
                anchors.topMargin: 64
                spacing: 9
                opacity: root.closeOpacity * root.phase(0.06, 0.28)

                Text {
                    text: "BOOTSTRAP // LIVE"
                    color: Theme.accent2
                    font.family: Theme.sans
                    font.pixelSize: 11
                    font.letterSpacing: 2
                }

                Text {
                    text: "CAT // " + root.sourceLabel
                    color: Theme.dim
                    font.family: Theme.sans
                    font.pixelSize: 10
                    font.letterSpacing: 1
                }
            }

            Item {
                id: rightTerminal
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.rightMargin: 56
                anchors.topMargin: 64
                anchors.bottomMargin: 64
                width: Math.min(parent.width * 0.34, 560)
                opacity: root.closeOpacity * root.phase(0.12, 0.3)

                Repeater {
                    model: root.codeLines.length

                    Text {
                        required property int index
                        property string sourceLine: root.codeLines[index] || ""
                        width: parent.width
                        height: 14
                        y: index * 18
                        text: {
                            var content = index === root.codeLineIndex
                                ? sourceLine.slice(0, Math.min(root.codeChars, sourceLine.length))
                                : sourceLine
                            return (index === root.codeLineIndex ? "› " : "  ") + content
                        }
                        color: index === root.codeLineIndex ? Theme.bright : Theme.dim
                        font.family: Theme.sans
                        font.pixelSize: 12
                        opacity: index > root.codeLineIndex ? 0 : (index === root.codeLineIndex ? 1 : 0.38)
                        elide: Text.ElideRight
                    }
                }
            }

            Item {
                anchors.left: parent.left
                anchors.right: rightTerminal.left
                anchors.bottom: parent.bottom
                anchors.leftMargin: 56
                anchors.rightMargin: 32
                anchors.bottomMargin: 64
                height: Math.max(250, parent.height * 0.38)
                opacity: root.closeOpacity * root.phase(0.18, 0.32)

                Item {
                    anchors.fill: parent
                    anchors.margins: 22

                    Repeater {
                        model: root.lowerCodeLines.length

                        Text {
                            required property int index
                            property string sourceLine: root.lowerCodeLines[index] || ""
                            width: parent.width
                            height: 14
                            y: root.lowerCodeLines.length > 1
                                ? index * (parent.height - height) / (root.lowerCodeLines.length - 1)
                                : 0
                            text: {
                                var content = index === root.lowerCodeLineIndex
                                    ? sourceLine.slice(0, Math.min(root.lowerCodeChars, sourceLine.length))
                                    : sourceLine
                                return String(index + 1).padStart(2, "0") + "  "
                                    + (index === root.lowerCodeLineIndex ? "› " : "  ") + content
                            }
                            color: index === root.lowerCodeLineIndex ? Theme.bright : Theme.dim
                            font.family: Theme.sans
                            font.pixelSize: 12
                            opacity: index > root.lowerCodeLineIndex
                                ? 0
                                : (index === root.lowerCodeLineIndex ? 1 : 0.52)
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 56
                anchors.rightMargin: 56
                anchors.bottomMargin: 42
                height: 1
                color: Theme.alpha(Theme.accent, 0.28)
                opacity: root.closeOpacity * root.phase(0.08, 0.25)
            }
        }
    }
}
