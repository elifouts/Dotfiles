import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import "./theme" as RetroTheme

Variants {
    id: shell
    model: Quickshell.screens
    property bool shown: true

    PanelWindow {
        id: bar
        required property var modelData
        screen: modelData
        readonly property string screenKey: modelData === Quickshell.screens[0] ? "primary" : "secondary"
        visible: shell.shown
        anchors { top: true; left: true; right: true }
        implicitHeight: 44
        readonly property bool mainScreen: modelData.name === "DP-5"
        exclusiveZone: shell.shown ? implicitHeight : 0
        color: "transparent"

        readonly property var monitor: Hyprland.monitors.values.find(item => item.name === modelData.name)
        readonly property int activeWorkspace: Hyprland.focusedWorkspace?.id ?? 1
        IpcHandler {
            target: modelData === Quickshell.screens[0] ? "bar" : "bar-secondary"
            function toggle(): void { shell.shown = !shell.shown }
            function cycle(): void { }
        }
        readonly property var player: Mpris.players.values.find(item => item.dbusName?.toLowerCase().includes("spotify")) ?? Mpris.players.values[0] ?? null
        property real playbackProgress: 0
        readonly property var localTasks: Hyprland.toplevels.values.filter(item => item.workspace?.monitor?.name === modelData.name).slice(0, 6)
        property string cpu: "--"
        property string cpuTemp: "--"
        property string memory: "--"
        property var barZones: ({ left: ["user", "media", "workspaces"], center: ["clock", "audio"], right: ["network", "settings"] })

        function run(command) { Quickshell.execDetached(["sh", "-c", command]) }
        function hasModule(name) { return bar.barZones.left.indexOf(name) >= 0 || bar.barZones.center.indexOf(name) >= 0 || bar.barZones.right.indexOf(name) >= 0 }
        function refresh(process) { process.running = false; process.running = true }

        Process { id: cpuProcess; command: ["sh", "-c", "top -bn1 | awk '/Cpu\\(s\\)/ { printf \"%02d%%\", 100 - $8 }'"]; running: true; stdout: StdioCollector { onStreamFinished: { bar.cpu = this.text.trim() || "--"; cpuProcess.running = false } } }
        Process { id: temperatureProcess; command: ["sh", "-c", "sensors 2>/dev/null | awk '/Package id 0:|Tctl:|temp1:/ {gsub(/[+°C]/,\"\",$3); print $3; exit}'"]; running: true; stdout: StdioCollector { onStreamFinished: { bar.cpuTemp = this.text.trim() || "--"; temperatureProcess.running = false } } }
        Process { id: memoryProcess; command: ["sh", "-c", "free -m | awk '/Mem:/ { printf \"%sM\", $3 }'"]; running: true; stdout: StdioCollector { onStreamFinished: { bar.memory = this.text.trim() || "--"; memoryProcess.running = false } } }
        Process { id: moduleOrderProcess; command: ["sh", "-c", "cat \"$HOME/.cache/quickshell/bar-modules.json\" 2>/dev/null"]; running: true; stdout: StdioCollector { onStreamFinished: { try { const saved = JSON.parse(this.text.trim()); if (saved.screens && saved.screens[bar.screenKey]) bar.barZones = saved.screens[bar.screenKey]; else if (saved.left) bar.barZones = bar.migrateZones(saved); } catch (error) {} moduleOrderProcess.running = false } } }
        Timer { interval: 1000; running: true; repeat: true; onTriggered: { moduleOrderProcess.running = false; moduleOrderProcess.running = true } }
        Timer { interval: 3000; running: true; repeat: true; onTriggered: { bar.refresh(cpuProcess); bar.refresh(temperatureProcess); bar.refresh(memoryProcess) } }
        Timer { interval: 200; running: bar.player?.isPlaying ?? false; repeat: true; onTriggered: if (bar.player && bar.player.length > 0) bar.playbackProgress = Math.min(1, bar.player.position / bar.player.length) }

        component Module: Rectangle {
            property alias text: content.text
            property var action
            property bool interactive: true
            property int fontSize: 11
            implicitHeight: 34
            radius: 2
            color: hover.containsMouse ? RetroTheme.Theme.surfaceAlt : RetroTheme.Theme.surface
            border.color: hover.containsMouse ? RetroTheme.Theme.accentAlt : RetroTheme.Theme.border
            border.width: 1
            scale: hover.containsMouse ? 1.015 : 1
            Behavior on color { ColorAnimation { duration: 110 } }
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: 120 } }
            Text { id: content; anchors.centerIn: parent; color: RetroTheme.Theme.foreground; font.family: "JetBrains Mono"; font.pixelSize: parent.fontSize; font.bold: true; elide: Text.ElideRight }
            MouseArea { id: hover; anchors.fill: parent; enabled: parent.interactive; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (parent.action) parent.action() }
        }

        component MusicViz: Row {
            property bool active: bar.player?.isPlaying ?? false
            spacing: 2
            width: 16
            height: 18
            Repeater {
                model: 3
                Rectangle {
                    required property int index
                    width: 4
                    height: active ? 5 + index * 3 : 4
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 2
                    color: RetroTheme.Theme.purple
                    SequentialAnimation on height {
                        running: active
                        loops: Animation.Infinite
                        NumberAnimation { to: 5 + index * 2; duration: 170 + index * 60; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 15 - index * 2; duration: 220 + index * 50; easing.type: Easing.InOutSine }
                    }
                }
            }
        }

        component VolumeModule: Rectangle {
            id: volumeWidget
            property real level: 0.5
            property bool muted: false
            property bool expanded: hoverHandler.hovered
            implicitHeight: 34
            width: expanded ? 142 : 58
            radius: 3
            color: expanded ? RetroTheme.Theme.surfaceAlt : RetroTheme.Theme.surface
            border.color: expanded ? RetroTheme.Theme.purple : RetroTheme.Theme.border
            border.width: 1
            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
            Process { id: volumeProcess; command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print $2, $3}'"]; running: true; stdout: StdioCollector { onStreamFinished: { const parts = this.text.trim().split(/\\s+/); const next = parseFloat(parts[0]); if (!isNaN(next)) volumeWidget.level = Math.max(0, Math.min(1, next)); volumeWidget.muted = parts[1] === "MUTED"; volumeProcess.running = false } } }
            Timer { interval: 1000; running: true; repeat: true; onTriggered: { volumeProcess.running = false; volumeProcess.running = true } }
            Row {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 7
                Text { text: volumeWidget.muted ? "\uf026" : volumeWidget.level < 0.33 ? "\uf027" : "\uf028"; color: volumeWidget.muted ? RetroTheme.Theme.red : RetroTheme.Theme.purple; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
                Rectangle {
                    visible: volumeWidget.expanded
                    width: 78
                    height: 6
                    radius: 3
                    color: RetroTheme.Theme.border
                    anchors.verticalCenter: parent.verticalCenter
                    Rectangle { width: parent.width * volumeWidget.level; height: parent.height; radius: 3; color: RetroTheme.Theme.purple; Behavior on width { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } } }
                    MouseArea { anchors.fill: parent; onPressed: function(mouse) { volumeWidget.setLevel(mouse.x / parent.width) }; onPositionChanged: function(mouse) { if (pressed) volumeWidget.setLevel(mouse.x / parent.width) } }
                }
                Text { text: Math.round(volumeWidget.level * 100) + "%"; color: RetroTheme.Theme.foreground; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
            }
            HoverHandler { id: hoverHandler }
            function setLevel(next) { level = Math.max(0, Math.min(1, next)); Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", level.toFixed(2)]) }
        }

        component UserModule: Module { width: 145; text: "// " + (Quickshell.env("HOSTNAME") || Quickshell.env("USER") || "USER"); border.color: RetroTheme.Theme.accent; interactive: false }
        component MediaModule: Module { width: 205; text: bar.player ? bar.player.trackTitle : "idle"; border.color: RetroTheme.Theme.purple; action: () => bar.run("$HOME/.config/hypr/Retro/utilities/quickshell-panel.sh media"); MusicViz { anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter } Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 5; height: 3; radius: 2; color: RetroTheme.Theme.border; Rectangle { width: parent.width * bar.playbackProgress; height: parent.height; radius: 2; color: RetroTheme.Theme.purple; Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } } } } }
        component WorkspacesModule: Module { interactive: false; width: 190; Row { anchors.centerIn: parent; spacing: 5; Repeater { model: 10; Item { required property int index; property var workspace: Hyprland.workspaces.values.find(item => item.id === index + 1); property bool selected: bar.activeWorkspace === index + 1; property int windows: workspace?.toplevels.values.length ?? 0; width: 12; height: 8 + Math.min(22, windows * 5); Rectangle { anchors.centerIn: parent; width: 4; height: parent.height; radius: 2; color: selected ? RetroTheme.Theme.accent : windows > 0 ? RetroTheme.Theme.accentAlt : RetroTheme.Theme.border } MouseArea { anchors.fill: parent; onClicked: bar.run("$HOME/.config/hypr/utilities/workspace-overview.sh") } } } } }

        Component { id: userModule; UserModule { } }
        Component { id: mediaModule; MediaModule { } }
        Component { id: workspacesModule; WorkspacesModule { } }

        function migrateZones(saved) { const all = ["user", "media", "workspaces", "clock", "audio", "network", "settings"]; const next = ({ left: saved.left.slice(), center: saved.center.slice(), right: saved.right.slice() }); all.forEach(name => { if (next.left.indexOf(name) < 0 && next.center.indexOf(name) < 0 && next.right.indexOf(name) < 0) next.left.push(name); }); next.version = 3; return next }

        Item {
            anchors.fill: parent
            anchors.margins: 5
            opacity: shell.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            Module { id: user; visible: false; anchors.left: parent.left; anchors.leftMargin: 4; width: 145; text: "// " + (Quickshell.env("HOSTNAME") || Quickshell.env("USER") || "USER"); border.color: RetroTheme.Theme.accent; interactive: false }

            Module { id: media; visible: false; anchors.left: user.right; anchors.leftMargin: 5; width: 205; text: bar.player ? bar.player.trackTitle : "idle"; border.color: RetroTheme.Theme.purple; action: () => bar.run("$HOME/.config/hypr/Retro/utilities/quickshell-panel.sh media"); MusicViz { anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter } }

            Module {
                id: workspaces
                visible: false
                interactive: false
                anchors.left: bar.mainScreen ? media.right : parent.left
                anchors.leftMargin: bar.mainScreen ? 5 : 8
                width: 190
                Row {
                    anchors.centerIn: parent
                    spacing: 5
                    Repeater {
                        model: 10
                        Item {
                            required property int index
                            property var workspace: Hyprland.workspaces.values.find(item => item.id === index + 1)
                            property bool selected: bar.activeWorkspace === index + 1
                            property int windows: workspace?.toplevels.values.length ?? 0
                            width: 12
                            height: 8 + Math.min(22, windows * 5)
                            anchors.verticalCenter: parent.verticalCenter
                            Rectangle {
                                anchors.centerIn: parent
                                width: 4
                                height: parent.height
                                radius: 2
                                color: workspaceHover.containsMouse ? RetroTheme.Theme.accentAlt : selected ? RetroTheme.Theme.accent : windows > 0 ? RetroTheme.Theme.accentAlt : RetroTheme.Theme.border
                                Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 140 } }
                            }
                            MouseArea { id: workspaceHover; anchors.fill: parent; acceptedButtons: Qt.LeftButton; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: bar.run("$HOME/.config/hypr/utilities/workspace-overview.sh") }
                        }
                    }
                }
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(0, parent.width / 3 - 10)
                spacing: 5
                clip: true
                Repeater {
                    model: bar.barZones.left
                    Loader {
                        required property string modelData
                        sourceComponent: modelData === "user" ? userModule : modelData === "media" ? mediaModule : modelData === "workspaces" ? workspacesModule : modelData === "clock" ? clockModule : modelData === "audio" ? audioModule : modelData === "network" ? networkModule : settingsModule
                    }
                }
            }

            Row { anchors.horizontalCenter: parent.horizontalCenter; anchors.verticalCenter: parent.verticalCenter; width: Math.max(0, parent.width / 3 - 10); spacing: 5; clip: true; Repeater { model: bar.barZones.center; Loader { required property string modelData; sourceComponent: modelData === "user" ? userModule : modelData === "media" ? mediaModule : modelData === "workspaces" ? workspacesModule : modelData === "clock" ? clockModule : modelData === "audio" ? audioModule : modelData === "network" ? networkModule : settingsModule } } }
            Row { anchors.right: parent.right; anchors.rightMargin: 4; anchors.verticalCenter: parent.verticalCenter; width: Math.max(0, parent.width / 3 - 10); spacing: 5; clip: true; layoutDirection: Qt.RightToLeft; Repeater { model: bar.barZones.right; Loader { required property string modelData; sourceComponent: modelData === "user" ? userModule : modelData === "media" ? mediaModule : modelData === "workspaces" ? workspacesModule : modelData === "clock" ? clockModule : modelData === "audio" ? audioModule : modelData === "network" ? networkModule : settingsModule } } }

            Component {
                id: clockModule
                Module { width: 205; text: Qt.formatDateTime(new Date(), "hh:mm:ss AP  •  ddd dd MMM"); border.color: RetroTheme.Theme.blue; action: () => bar.run("$HOME/.config/hypr/Retro/utilities/quickshell-panel.sh calendar"); Timer { interval: 1000; running: true; repeat: true; onTriggered: parent.text = Qt.formatDateTime(new Date(), "hh:mm:ss AP  •  ddd dd MMM") } }
            }
            Component {
                id: audioModule
                VolumeModule { }
            }
            Component {
                id: networkModule
                Module { width: 92; text: "⌁ INTERNET"; border.color: RetroTheme.Theme.green; action: () => bar.run("$HOME/.config/hypr/Retro/utilities/quickshell-panel.sh network") }
            }
            Component {
                id: settingsModule
                Module { width: 94; text: "⚙ SETTINGS"; border.color: RetroTheme.Theme.red; action: () => bar.run("$HOME/.config/hypr/Retro/utilities/quickshell-panel.sh settings") }
            }
        }
    }
}
