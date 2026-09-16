import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "./theme" as RetroTheme
import Quickshell.Services.Mpris

PanelWindow {
    id: panel
    anchors { top: true; bottom: true; left: true; right: true }
    implicitWidth: 1
    implicitHeight: mode === "audio" ? 260 : mode === "network" ? 520 : mode === "bar" ? 700 : mode === "calendar" ? 360 : mode === "power" ? 250 : mode === "media" ? 430 : mode === "settings" ? 580 : 230
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-panel"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    color: "transparent"
    property bool closing: false
    property string mode: Quickshell.env("QS_PANEL_MODE") || "audio"
    property string wifi: "scanning..."
    property string selectedSsid: ""
    property date shownMonth: new Date()
    property string battery: "--"
    property string cpu: "--"
    property string gpu: "--"
    property string memory: "--"
    property real brightness: 0.5
    property real volumeLevel: 0.5
    property bool muted: false
    property bool wifiEnabled: true
    property string ethernet: "No Ethernet"
    property var barZones: ({ left: ["user", "media", "workspaces"], center: ["clock", "audio"], right: ["network", "settings"] })
    property var screenLayouts: ({ primary: barZones, secondary: barZones })
    property var layoutPresets: ({ one: ({ left: ["user", "media", "workspaces"], center: ["clock", "audio"], right: ["network", "settings"] }), two: ({ left: ["user", "workspaces"], center: ["media", "clock"], right: ["audio", "network", "settings"] }), three: ({ left: ["user"], center: ["workspaces", "media", "clock"], right: ["audio", "network", "settings"] }) })
    property string activeScreenKey: "primary"
    readonly property var player: Mpris.players.values.find(item => item.dbusName?.toLowerCase().includes("spotify")) ?? Mpris.players.values[0] ?? null

    component RetroButton: Button {
        implicitHeight: 38
        scale: down ? 0.97 : hovered ? 1.025 : 1
        opacity: enabled ? 1 : 0.45
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 140 } }
        background: Rectangle { radius: 10; color: parent.down ? RetroTheme.Theme.accent : parent.hovered ? RetroTheme.Theme.surfaceAlt : RetroTheme.Theme.background; border.color: parent.down ? RetroTheme.Theme.accent : parent.hovered ? RetroTheme.Theme.accentAlt : RetroTheme.Theme.border; border.width: 1; Behavior on color { ColorAnimation { duration: 150 } } Behavior on border.color { ColorAnimation { duration: 150 } } }
        contentItem: Text { text: parent.text; color: parent.down ? RetroTheme.Theme.background : RetroTheme.Theme.foreground; font.family: "JetBrsettingsains Mono"; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
    }

    component LayoutButton: Button { implicitHeight: 30; scale: down ? 0.97 : hovered ? 1.025 : 1; opacity: enabled ? 1 : 0.45; Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } } Behavior on opacity { NumberAnimation { duration: 140 } } background: Rectangle { radius: 7; color: parent.down ? RetroTheme.Theme.accent : parent.hovered ? RetroTheme.Theme.surfaceAlt : RetroTheme.Theme.background; border.color: parent.hovered ? RetroTheme.Theme.accentAlt : RetroTheme.Theme.border; border.width: 1 } contentItem: Text { text: parent.text; color: parent.down ? RetroTheme.Theme.background : RetroTheme.Theme.foreground; font.family: "JetBrains Mono"; font.pixelSize: 8; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight } }

    component MusicButton: Button {
        implicitWidth: 32
        implicitHeight: 32
        scale: down ? 0.92 : hovered ? 1.08 : 1
        Behavior on scale { NumberAnimation { duration: 170; easing.type: Easing.OutBack } }
        background: Rectangle { radius: 8; color: parent.down ? RetroTheme.Theme.purple : parent.hovered ? RetroTheme.Theme.surfaceAlt : RetroTheme.Theme.background; border.color: parent.down || parent.hovered ? RetroTheme.Theme.purple : RetroTheme.Theme.border; border.width: 1; Behavior on color { ColorAnimation { duration: 120 } } }
        contentItem: Text { text: parent.text; color: parent.down ? RetroTheme.Theme.background : RetroTheme.Theme.purple; font.family: "JetBrains Mono"; font.pixelSize: 12; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
    }

    component MusicViz: Row {
        property bool active: panel.player?.isPlaying ?? false
        spacing: 3
        width: 21
        height: 22
        Repeater {
            model: 3
            Rectangle {
                required property int index
                width: 5
                height: active ? 7 + ((index + 1) * 4) : 5
                anchors.verticalCenter: parent.verticalCenter
                radius: 2
                color: RetroTheme.Theme.purple
                Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.InOutSine } }
                SequentialAnimation on height {
                    running: active
                    loops: Animation.Infinite
                    NumberAnimation { to: 6 + (index * 5); duration: 220 + index * 70; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 18 - (index * 3); duration: 260 + index * 60; easing.type: Easing.InOutSine }
                }
            }
        }
    }

    component AudioButton: Button {
        implicitWidth: 74
        implicitHeight: 34
        scale: down ? 0.97 : hovered ? 1.025 : 1
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        background: Rectangle { radius: 8; color: parent.down ? RetroTheme.Theme.purple : parent.hovered ? RetroTheme.Theme.surfaceAlt : RetroTheme.Theme.background; border.color: parent.down || parent.hovered ? RetroTheme.Theme.purple : RetroTheme.Theme.border; border.width: 1; Behavior on color { ColorAnimation { duration: 120 } } }
        contentItem: Text { text: parent.text; color: parent.down ? RetroTheme.Theme.background : RetroTheme.Theme.foreground; font.family: "JetBrains Mono"; font.pixelSize: 9; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
    }

    component RetroSlider: Item {
        id: slider
        property real value: 0.5
        property color tint: RetroTheme.Theme.accent
        signal moved(real nextValue)
        implicitHeight: 38
        Rectangle { id: track; anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: 12; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; height: 7; radius: 4; color: RetroTheme.Theme.border
            Rectangle { width: track.width * slider.value; height: parent.height; radius: 4; color: slider.tint; Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } } }
        }
        Rectangle { id: handle; x: track.x + track.width * slider.value - width / 2; anchors.verticalCenter: track.verticalCenter; width: 20; height: 20; radius: 10; color: dragArea.pressed ? RetroTheme.Theme.foreground : slider.tint; border.color: RetroTheme.Theme.background; border.width: 2; Behavior on x { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } } }
        MouseArea { id: dragArea; z: 10; preventStealing: true; anchors.fill: parent; acceptedButtons: Qt.LeftButton; cursorShape: Qt.PointingHandCursor; onPressed: function(mouse) { slider.setFrom(mouse.x) }; onPositionChanged: function(mouse) { if (pressed) slider.setFrom(mouse.x) } }
        function setFrom(position) { slider.value = Math.max(0, Math.min(1, (position - track.x) / track.width)); slider.moved(slider.value) }
    }

    component SettingRow: Button {
        id: settingRow
        property string iconGlyph: "•"
        property string subtitle: ""
        property color tint: RetroTheme.Theme.blue
        implicitHeight: 52
        scale: down ? 0.985 : hovered ? 1.015 : 1
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        background: Rectangle { radius: 12; color: settingRow.down ? Qt.darker(settingRow.tint, 1.35) : settingRow.hovered ? RetroTheme.Theme.surfaceAlt : RetroTheme.Theme.background; border.color: settingRow.down ? settingRow.tint : settingRow.hovered ? settingRow.tint : RetroTheme.Theme.border; border.width: settingRow.down || settingRow.hovered ? 2 : 1; Behavior on color { ColorAnimation { duration: 160 } } Behavior on border.color { ColorAnimation { duration: 160 } } }
        contentItem: RowLayout {
            spacing: 12
            Text { text: settingRow.iconGlyph; color: settingRow.tint; font.pixelSize: 19; Layout.preferredWidth: 24; horizontalAlignment: Text.AlignHCenter }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text { text: settingRow.text; color: RetroTheme.Theme.foreground; font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true; elide: Text.ElideRight }
                Text { text: settingRow.subtitle; visible: text.length > 0; color: RetroTheme.Theme.muted; font.family: "JetBrains Mono"; font.pixelSize: 9; elide: Text.ElideRight }
            }
            Text { text: ">"; color: settingRow.hovered ? settingRow.tint : RetroTheme.Theme.muted; font.pixelSize: 17; Layout.preferredWidth: 18; horizontalAlignment: Text.AlignHCenter; Behavior on color { ColorAnimation { duration: 130 } } }
        }
    }

    component ActionTile: Button {
        id: tile
        property string iconGlyph: "•"
        property color tint: RetroTheme.Theme.blue
        property string tooltipText: ""
        implicitWidth: 58
        implicitHeight: 58
        scale: down ? 0.94 : hovered ? 1.04 : 1
        Behavior on scale { NumberAnimation { duration: 170; easing.type: Easing.OutBack } }
        ToolTip.text: tile.tooltipText
        ToolTip.visible: tile.hovered && tile.tooltipText.length > 0
        ToolTip.delay: 450
        background: Rectangle { radius: 8; color: tile.down ? tile.tint : tile.hovered ? RetroTheme.Theme.surfaceAlt : RetroTheme.Theme.background; border.color: tile.down || tile.hovered ? tile.tint : RetroTheme.Theme.border; border.width: tile.down || tile.hovered ? 2 : 1; Behavior on color { ColorAnimation { duration: 140 } } Behavior on border.color { ColorAnimation { duration: 140 } } }
        contentItem: Text { text: tile.iconGlyph; color: tile.down ? RetroTheme.Theme.background : tile.tint; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 23; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
    }

    component SettingsTile: ActionTile { implicitWidth: 92; implicitHeight: 56; Layout.preferredWidth: 92; contentItem: Text { text: parent.iconGlyph; color: parent.down ? RetroTheme.Theme.background : parent.tint; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 21; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter } }

    component InfoTile: Rectangle {
        property string iconGlyph: "•"
        property string valueText: "--"
        property color tint: RetroTheme.Theme.blue
        Layout.preferredWidth: 92
        Layout.preferredHeight: 56
        radius: 10
        color: RetroTheme.Theme.background
        border.color: RetroTheme.Theme.border
        border.width: 1
        Column {
            anchors.centerIn: parent
            spacing: 2
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: iconGlyph; color: tint; font.pixelSize: 18 }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: valueText; color: RetroTheme.Theme.foreground; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true }
        }
    }

    component ModulePage: ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumWidth: 0
        spacing: 14
    }

    component SettingsGrid: GridLayout {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        columns: 3
        columnSpacing: 8
        rowSpacing: 8
    }

    component LayoutZone: Rectangle {
        property string zoneName: "left"
        property string zoneTitle: "LEFT"
        property string screenKey: "primary"
        property var zoneItems: []
        Layout.minimumWidth: 210
        Layout.preferredWidth: 1
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 10
        color: RetroTheme.Theme.background
        border.color: RetroTheme.Theme.border
        border.width: 1
        Behavior on border.color { ColorAnimation { duration: 140 } }
        ColumnLayout { anchors.fill: parent; anchors.margins: 8; spacing: 6; Text { text: zoneTitle; color: RetroTheme.Theme.accent; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true } ListView { id: zoneList; Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 5; model: zoneItems; delegate: Rectangle { id: zoneChip; required property string modelData; width: zoneList.width; height: 40; radius: 7; color: drag.active ? RetroTheme.Theme.accent : RetroTheme.Theme.surface; border.color: drag.active ? RetroTheme.Theme.accentAlt : RetroTheme.Theme.border; Text { anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter; text: zoneChip.modelData.toUpperCase(); color: drag.active ? RetroTheme.Theme.background : RetroTheme.Theme.foreground; font.family: "JetBrains Mono"; font.pixelSize: 9; font.bold: true } Row { anchors.right: parent.right; anchors.rightMargin: 5; anchors.verticalCenter: parent.verticalCenter; spacing: 2; Repeater { model: ["left", "center", "right"]; Rectangle { required property string modelData; width: 18; height: 20; radius: 4; color: zoneName === modelData ? RetroTheme.Theme.accent : RetroTheme.Theme.surfaceAlt; Text { anchors.centerIn: parent; text: modelData === "left" ? "L" : modelData === "center" ? "C" : "R"; color: zoneName === modelData ? RetroTheme.Theme.background : RetroTheme.Theme.muted; font.family: "JetBrains Mono"; font.pixelSize: 8; font.bold: true } MouseArea { anchors.fill: parent; onClicked: panel.moveModule(zoneChip.modelData, zoneName, modelData) } } } Rectangle { width: 18; height: 20; radius: 4; color: RetroTheme.Theme.surfaceAlt; Text { anchors.centerIn: parent; text: "×"; color: RetroTheme.Theme.red; font.pixelSize: 13 } MouseArea { anchors.fill: parent; onClicked: panel.removeModule(zoneChip.modelData, zoneName) } } } DragHandler { id: drag; onActiveChanged: if (!active) panel.dropModule(zoneChip.modelData, zoneName, zoneChip.mapToItem(layoutEditor, zoneChip.width / 2, zoneChip.height / 2)) } } } }
    }

    Process {
        id: wifiProcess
        command: ["sh", "-c", "printf 'WIFI\\n'; nmcli -t --escape no -f IN-USE,SIGNAL,SSID dev wifi list 2>/dev/null | head -12; printf '\\nETHERNET\\n'; nmcli -t --escape no -f DEVICE,TYPE,STATE,CONNECTION dev 2>/dev/null | awk -F: '$2==\"ethernet\" {print $1 \"  \" $3 \"  \" $4}'"]
        running: mode === "network"
        stdout: StdioCollector { onStreamFinished: panel.wifi = this.text.trim() || "No networks found" }
    }
    Process { id: settingsCpu; command: ["sh", "-c", "top -bn1 | awk '/Cpu\\(s\\)/ { printf \"%02d%%\", 100 - $8 }'"]; running: mode === "settings"; stdout: StdioCollector { onStreamFinished: panel.cpu = this.text.trim() || "--" } }
    Process { id: settingsMemory; command: ["sh", "-c", "free -m | awk '/Mem:/ { printf \"%sM\", $3 }'"]; running: mode === "settings"; stdout: StdioCollector { onStreamFinished: panel.memory = this.text.trim() || "--" } }
    Process { id: brightnessProcess; command: ["sh", "-c", "brightnessctl -m 2>/dev/null | awk -F, '{gsub(/%/,\"\",$4); print $4/100}'"]; running: mode === "settings"; stdout: StdioCollector { onStreamFinished: { const value = parseFloat(this.text.trim()); panel.brightness = isNaN(value) ? 0.5 : value } } }
    Process { id: volumeProcess; command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print $2, $3}'"]; running: mode === "audio" || mode === "settings"; stdout: StdioCollector { onStreamFinished: { const value = parseFloat(this.text.trim()); panel.volumeLevel = isNaN(value) ? panel.volumeLevel : Math.max(0, Math.min(1, value)); panel.muted = this.text.includes("MUTED") } } }
    Timer { interval: 1000; running: mode === "audio" || mode === "settings"; repeat: true; onTriggered: { volumeProcess.running = false; volumeProcess.running = true } }
    Process { id: wifiStateProcess; command: ["sh", "-c", "nmcli -t -f WIFI g; printf '\\n'; nmcli -t -f DEVICE,TYPE,STATE,CONNECTION dev | awk -F: '$2==\"ethernet\" {print $1 \"  \" $3 \"  \" $4}'"]; running: mode === "network" || mode === "settings"; stdout: StdioCollector { onStreamFinished: { const lines = this.text.trim().split("\n"); panel.wifiEnabled = lines[0] !== "disabled"; panel.ethernet = lines[1] || "No Ethernet" } } }
        Process { id: barOrderProcess; command: ["sh", "-c", "cat \"$HOME/.cache/quickshell/bar-modules.json\" 2>/dev/null"]; running: mode === "bar"; stdout: StdioCollector { onStreamFinished: { try { const saved = JSON.parse(this.text.trim()); if (saved.presets) panel.layoutPresets = saved.presets; if (saved.screens) { panel.screenLayouts = saved.screens; panel.loadScreen(panel.activeScreenKey); } else if (saved.left) { const migrated = panel.migrateZones(saved); panel.screenLayouts = ({ primary: migrated, secondary: migrated }); panel.barZones = migrated; } } catch (error) {} } } }
    Process {
        id: batteryProcess
        command: ["sh", "-c", "c=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1); s=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1); printf '%s%% %s' \"${c:---}\" \"${s:-AC}\""]
        running: mode === "power" || mode === "settings"
        stdout: StdioCollector { onStreamFinished: panel.battery = this.text.trim() || "AC" }
    }

    MouseArea { anchors.fill: parent; onClicked: function(mouse) { if (mouse.x < panelCard.x || mouse.x > panelCard.x + panelCard.width || mouse.y < panelCard.y || mouse.y > panelCard.y + panelCard.height) panel.close() } }

    Rectangle {
        id: panelCard
        x: mode === "media" ? 12 : Math.max(12, parent.width - width - 12)
        width: Math.max(0, Math.min(mode === "bar" ? 760 : 390, parent.width - 24))
        z: 1
        height: Math.max(0, Math.min(panel.implicitHeight, parent.height - 64))
        color: RetroTheme.Theme.surface
        border.color: mode === "audio" ? RetroTheme.Theme.purple : mode === "network" ? RetroTheme.Theme.green : mode === "power" ? RetroTheme.Theme.red : RetroTheme.Theme.blue
        border.width: 2
        radius: 6
        opacity: 0
        focus: true
        property real restingY: 52
        y: restingY + 12
        Component.onCompleted: { opacity = 1; y = restingY }
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 280; easing.type: Easing.OutBack } }
        ParallelAnimation {
            id: closeAnimation
            NumberAnimation { target: panelCard; property: "opacity"; to: 0; duration: 110; easing.type: Easing.InCubic }
            NumberAnimation { target: panelCard; property: "y"; to: panelCard.y + 18; duration: 160; easing.type: Easing.InCubic }
            onFinished: Qt.quit()
        }
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14
            clip: false
            RowLayout {
                Layout.fillWidth: true
                Text { text: mode === "settings" || mode === "power" ? "// SETTINGS" : mode === "bar" ? "// PANEL LAYOUT" : mode === "audio" ? "// AUDIO CONTROL" : mode === "network" ? "// NETWORK CONTROL" : mode === "media" ? "// MUSIC" : "// CALENDAR"; color: mode === "settings" || mode === "power" ? RetroTheme.Theme.orange : mode === "bar" ? RetroTheme.Theme.accent : mode === "audio" ? RetroTheme.Theme.purple : mode === "network" ? RetroTheme.Theme.green : RetroTheme.Theme.blue; font.family: "JetBrains Mono"; font.pixelSize: 15; font.bold: true }
                Item { Layout.fillWidth: true }
                Text { text: "ESC"; color: "#928374"; font.family: "JetBrains Mono"; font.pixelSize: 10 }
            }
            StackLayout { Layout.fillWidth: true; Layout.fillHeight: true; clip: true; currentIndex: mode === "audio" ? 0 : mode === "network" ? 1 : mode === "settings" ? 2 : mode === "bar" ? 3 : mode === "power" ? 4 : mode === "calendar" ? 5 : 6
                ModulePage {
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: panel.muted ? "◌" : "♫"; color: RetroTheme.Theme.purple; font.pixelSize: 26; Layout.preferredWidth: 34; horizontalAlignment: Text.AlignHCenter }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Text { text: "OUTPUT"; color: RetroTheme.Theme.muted; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true }
                            Text { text: Math.round(panel.volumeLevel * 100) + "%"; color: RetroTheme.Theme.foreground; font.family: "JetBrains Mono"; font.pixelSize: 25; font.bold: true }
                        }
                    }
                    RetroSlider { Layout.fillWidth: true; value: panel.volumeLevel; tint: RetroTheme.Theme.purple; onMoved: function(nextValue) { panel.setVolume(nextValue) } }
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 10
                        AudioButton { text: panel.muted ? "UNMUTE" : "MUTE"; onClicked: { Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]); panel.muted = !panel.muted } }
                        AudioButton { text: "MIXER"; onClicked: Quickshell.execDetached(["pavucontrol"]) }
                    }
                }
                ModulePage {
                    RowLayout { Layout.fillWidth: true; Text { text: "WIFI"; color: RetroTheme.Theme.muted; font.family: "JetBrains Mono"; font.pixelSize: 11 } Item { Layout.fillWidth: true } RetroButton { text: panel.wifiEnabled ? "ON" : "OFF"; onClicked: { Quickshell.execDetached(["nmcli", "radio", "wifi", panel.wifiEnabled ? "off" : "on"]); panel.wifiEnabled = !panel.wifiEnabled } } }
                    Text { Layout.fillWidth: true; text: panel.ethernet; color: RetroTheme.Theme.blue; font.family: "JetBrains Mono"; font.pixelSize: 11; elide: Text.ElideRight }
                    Text { text: "AVAILABLE ACCESS POINTS"; color: RetroTheme.Theme.muted; font.family: "JetBrains Mono"; font.pixelSize: 11 }
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 4
                        model: panel.wifi.split("\n").filter(line => line.length && !line.startsWith("WIFI") && !line.startsWith("ETHERNET"))
                        delegate: Rectangle {
                            required property string modelData
                            width: parent.width
                            height: 32
                            color: panel.selectedSsid === panel.wifiSsid(modelData) ? RetroTheme.Theme.accent : RetroTheme.Theme.background
                            Text { anchors.fill: parent; anchors.margins: 8; text: (modelData.startsWith("*") ? "● " : "○ ") + panel.wifiSsid(modelData) + "  " + panel.wifiSignal(modelData) + "%"; color: RetroTheme.Theme.foreground; font.family: "JetBrains Mono"; font.pixelSize: 11; elide: Text.ElideRight }
                            MouseArea { anchors.fill: parent; onClicked: panel.selectedSsid = panel.wifiSsid(modelData) }
                        }
                    }
                        TextInput {
                        id: password
                        Layout.fillWidth: true
                        visible: panel.selectedSsid.length > 0
                        echoMode: TextInput.Password
                        color: RetroTheme.Theme.foreground
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        Rectangle { anchors.fill: parent; anchors.margins: -5; color: "transparent"; border.color: RetroTheme.Theme.border; border.width: 1 }
                        Keys.onReturnPressed: connectWifi()
                    }
                        RowLayout {
                        Layout.fillWidth: true
                        RetroButton { text: "RESCAN"; onClicked: { Quickshell.execDetached(["nmcli", "dev", "wifi", "rescan"]); wifiProcess.running = false; wifiProcess.running = true } }
                        RetroButton { enabled: panel.selectedSsid.length > 0; text: "CONNECT"; onClicked: connectWifi() }
                        RetroButton { text: "DISCONNECT"; onClicked: Quickshell.execDetached(["nmcli", "connection", "down", panel.selectedSsid]) }
                        RetroButton { text: "NETWORK SETTINGS"; onClicked: Quickshell.execDetached(["nm-connection-editor"]) }
                    }
                }
                ModulePage {
                    Text { text: "SYSTEM STATUS"; color: RetroTheme.Theme.orange; font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true }
                    SettingsGrid {
                        InfoTile { Layout.fillWidth: true; Layout.minimumWidth: 0; Layout.preferredWidth: 1; iconGlyph: "◉"; valueText: panel.cpu; tint: RetroTheme.Theme.orange }
                        InfoTile { Layout.fillWidth: true; Layout.minimumWidth: 0; Layout.preferredWidth: 1; iconGlyph: "▦"; valueText: panel.memory; tint: RetroTheme.Theme.blue }
                        InfoTile { Layout.fillWidth: true; Layout.minimumWidth: 0; Layout.preferredWidth: 1; iconGlyph: "▰"; valueText: panel.battery; tint: RetroTheme.Theme.accentAlt }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "BRIGHTNESS"; color: RetroTheme.Theme.muted; font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text { text: Math.round(panel.brightness * 100) + "%"; color: RetroTheme.Theme.foreground; font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true }
                    }
                    RetroSlider {
                        id: settingsBrightness
                        Layout.fillWidth: true
                        value: panel.brightness
                        tint: RetroTheme.Theme.blue
                        onMoved: function(nextValue) { panel.brightness = nextValue; Quickshell.execDetached(["brightnessctl", "set", Math.round(nextValue * 100) + "%"]) }
                    }
                    Text { text: "QUICK ACTIONS"; color: RetroTheme.Theme.muted; font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true }
                    SettingsGrid {
                        SettingsTile { Layout.fillWidth: true; Layout.minimumWidth: 0; Layout.preferredWidth: 1; Layout.preferredHeight: 56; iconGlyph: "\uf108"; tooltipText: "Panel layout"; tint: RetroTheme.Theme.accent; onClicked: panel.openMode("bar") }
                        SettingsTile { Layout.fillWidth: true; Layout.minimumWidth: 0; Layout.preferredWidth: 1; Layout.preferredHeight: 56; iconGlyph: "\uf1eb"; tooltipText: "Internet"; tint: RetroTheme.Theme.green; onClicked: panel.openMode("network") }
                        SettingsTile { Layout.fillWidth: true; Layout.minimumWidth: 0; Layout.preferredWidth: 1; Layout.preferredHeight: 56; iconGlyph: "\uf028"; tooltipText: "Audio"; tint: RetroTheme.Theme.purple; onClicked: panel.openMode("audio") }
                        SettingsTile { Layout.fillWidth: true; Layout.minimumWidth: 0; Layout.preferredWidth: 1; Layout.preferredHeight: 56; iconGlyph: "\uf011"; tooltipText: "Power off"; tint: RetroTheme.Theme.red; onClicked: Quickshell.execDetached(["systemctl", "poweroff"]) }
                        SettingsTile { Layout.fillWidth: true; Layout.minimumWidth: 0; Layout.preferredWidth: 1; Layout.preferredHeight: 56; iconGlyph: "\uf2f1"; tooltipText: "Reboot"; tint: RetroTheme.Theme.orange; onClicked: Quickshell.execDetached(["systemctl", "reboot"]) }
                        SettingsTile { Layout.fillWidth: true; Layout.minimumWidth: 0; Layout.preferredWidth: 1; Layout.preferredHeight: 56; iconGlyph: "\uf2f5"; tooltipText: "Sign out"; tint: RetroTheme.Theme.muted; onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "exit"]) }
                    }
                }
                ModulePage {
                    id: layoutEditor
                    spacing: 8
                    RowLayout { Layout.fillWidth: true; Text { text: "EDITING BAR: " + panel.activeScreenKey.toUpperCase(); color: RetroTheme.Theme.accent; font.family: "JetBrains Mono"; font.pixelSize: 12; font.bold: true } LayoutButton { Layout.fillWidth: true; text: "PRIMARY BAR"; onClicked: panel.loadScreen("primary") } LayoutButton { Layout.fillWidth: true; text: "SECONDARY BAR"; onClicked: panel.loadScreen("secondary") } }
                                        RowLayout { Layout.fillWidth: true; Text { text: "PRESETS"; color: RetroTheme.Theme.muted; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true } LayoutButton { Layout.fillWidth: true; text: "SAVE 1"; onClicked: panel.savePreset("one") } LayoutButton { Layout.fillWidth: true; text: "SAVE 2"; onClicked: panel.savePreset("two") } LayoutButton { Layout.fillWidth: true; text: "SAVE 3"; onClicked: panel.savePreset("three") } }
                                        RowLayout { Layout.fillWidth: true; LayoutButton { Layout.fillWidth: true; text: "LOAD 1"; onClicked: panel.loadPreset("one") } LayoutButton { Layout.fillWidth: true; text: "LOAD 2"; onClicked: panel.loadPreset("two") } LayoutButton { Layout.fillWidth: true; text: "LOAD 3"; onClicked: panel.loadPreset("three") } }
                    Text { Layout.fillWidth: true; text: "DRAG INTO LEFT / CENTER / RIGHT  •  L C R ALSO MOVES ITEMS"; color: RetroTheme.Theme.muted; font.family: "JetBrains Mono"; font.pixelSize: 9; wrapMode: Text.Wrap }
                    RowLayout { Layout.fillWidth: true; Layout.fillHeight: true; spacing: 8; LayoutZone { screenKey: panel.activeScreenKey; zoneName: "left"; zoneTitle: "LEFT"; zoneItems: panel.barZones.left } LayoutZone { screenKey: panel.activeScreenKey; zoneName: "center"; zoneTitle: "CENTER"; zoneItems: panel.barZones.center } LayoutZone { screenKey: panel.activeScreenKey; zoneName: "right"; zoneTitle: "RIGHT"; zoneItems: panel.barZones.right } }
                    RowLayout { Layout.fillWidth: true; LayoutButton { Layout.fillWidth: true; text: "SAVE"; onClicked: panel.saveBarModules() } LayoutButton { Layout.fillWidth: true; text: "RESET BOTH BARS"; onClicked: panel.resetBarZones() } LayoutButton { Layout.fillWidth: true; text: "REMOVE SETTINGS BOTH"; onClicked: panel.removeModuleEverywhere("settings") } }
                    Flow { Layout.fillWidth: true; spacing: 4; LayoutButton { enabled: !panel.hasModule("user"); text: "ADD USER"; onClicked: panel.addModule("user") } LayoutButton { enabled: !panel.hasModule("media"); text: "ADD MUSIC"; onClicked: panel.addModule("media") } LayoutButton { enabled: !panel.hasModule("workspaces"); text: "ADD WORKSPACES"; onClicked: panel.addModule("workspaces") } LayoutButton { enabled: !panel.hasModule("clock"); text: "ADD CLOCK"; onClicked: panel.addModule("clock") } LayoutButton { enabled: !panel.hasModule("audio"); text: "ADD AUDIO"; onClicked: panel.addModule("audio") } LayoutButton { enabled: !panel.hasModule("network"); text: "ADD INTERNET"; onClicked: panel.addModule("network") } LayoutButton { enabled: !panel.hasModule("settings"); text: "ADD SETTINGS"; onClicked: panel.addModule("settings") } }
                }
                ModulePage {
                    Text { text: "SESSION POWER  //  " + panel.battery; color: RetroTheme.Theme.muted; font.family: "JetBrains Mono"; font.pixelSize: 11 }
                    RetroButton { Layout.fillWidth: true; text: "LOCK SESSION"; onClicked: Quickshell.execDetached(["hyprlock"]) }
                    RetroButton { Layout.fillWidth: true; text: "SIGN OUT"; onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "exit"]) }
                    RetroButton { Layout.fillWidth: true; text: "SHUT DOWN"; onClicked: Quickshell.execDetached(["systemctl", "poweroff"]) }
                    RetroButton { Layout.fillWidth: true; text: "REBOOT"; onClicked: Quickshell.execDetached(["systemctl", "reboot"]) }
                    RetroButton { Layout.fillWidth: true; text: "POWER OFF"; onClicked: Quickshell.execDetached(["systemctl", "poweroff"]) }
                }
                ModulePage {
                    RowLayout {
                        Layout.fillWidth: true
                        RetroButton { Layout.preferredWidth: 48; text: "<"; onClicked: panel.shownMonth = new Date(panel.shownMonth.getFullYear(), panel.shownMonth.getMonth() - 1, 1) }
                        Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: Qt.formatDateTime(panel.shownMonth, "MMMM yyyy"); color: RetroTheme.Theme.foreground; font.family: "JetBrains Mono"; font.bold: true }
                        RetroButton { Layout.preferredWidth: 48; text: ">"; onClicked: panel.shownMonth = new Date(panel.shownMonth.getFullYear(), panel.shownMonth.getMonth() + 1, 1) }
                    }
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 7
                        rowSpacing: 3
                        columnSpacing: 3
                        Repeater {
                            model: 42
                            Rectangle {
                                required property int index
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                color: index - new Date(panel.shownMonth.getFullYear(), panel.shownMonth.getMonth(), 1).getDay() + 1 === new Date().getDate() && panel.shownMonth.getMonth() === new Date().getMonth() ? RetroTheme.Theme.accent : RetroTheme.Theme.background
                                Text {
                                    anchors.centerIn: parent
                                    text: {
                                        const day = index - new Date(panel.shownMonth.getFullYear(), panel.shownMonth.getMonth(), 1).getDay() + 1
                                        return day > 0 && day <= new Date(panel.shownMonth.getFullYear(), panel.shownMonth.getMonth() + 1, 0).getDate() ? day : ""
                                    }
                                    color: index - new Date(panel.shownMonth.getFullYear(), panel.shownMonth.getMonth(), 1).getDay() + 1 === new Date().getDate() && panel.shownMonth.getMonth() === new Date().getMonth() ? RetroTheme.Theme.background : RetroTheme.Theme.foreground
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }
                }
                ModulePage {
                    spacing: 12
                    RowLayout { Layout.fillWidth: true; MusicViz { } Text { text: "NOW PLAYING"; color: RetroTheme.Theme.purple; font.family: "JetBrains Mono"; font.pixelSize: 13; font.bold: true } }
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 170
                        Layout.preferredHeight: 170
                        radius: 24
                        clip: true
                        color: RetroTheme.Theme.background
                        Image { anchors.fill: parent; source: panel.player?.trackArtUrl ?? ""; fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: true }
                    }
                    Text { Layout.fillWidth: true; text: panel.player?.trackTitle ?? "Nothing playing"; color: RetroTheme.Theme.foreground; font.family: "JetBrains Mono"; font.pixelSize: 15; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
                    Text { Layout.fillWidth: true; text: panel.player?.trackArtist ?? ""; color: RetroTheme.Theme.muted; font.family: "JetBrains Mono"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
                    RetroSlider {
                        id: musicPosition
                        z: 3
                        Layout.fillWidth: true
                        value: panel.player ? (panel.player.position / Math.max(1, panel.player.length)) : 0
                        tint: RetroTheme.Theme.purple
                        onMoved: function(nextValue) { if (panel.player) panel.player.position = nextValue * panel.player.length }
                    }
                    Timer { interval: 200; running: panel.player?.isPlaying ?? false; repeat: true; onTriggered: if (panel.player && panel.player.length > 0) musicPosition.value = Math.min(1, panel.player.position / panel.player.length) }
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        MusicButton { text: "|<"; onClicked: panel.player?.previous() }
                        MusicButton { text: panel.player?.isPlaying ? "||" : ">"; onClicked: panel.player?.togglePlaying() }
                        MusicButton { text: ">|"; onClicked: panel.player?.next() }
                    }
                }
            }
        }
        Keys.onEscapePressed: panel.close()
    }

    function connectWifi() {
        if (selectedSsid.length === 0) return;
        Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", selectedSsid, "password", password.text]);
        panel.close();
    }

    function openMode(nextMode) {
        closing = false;
        mode = nextMode;
    }

    function wifiSsid(line) {
        const first = line.indexOf(":");
        const second = line.indexOf(":", first + 1);
        return second < 0 ? line : line.slice(second + 1);
    }

    function wifiSignal(line) {
        const first = line.indexOf(":");
        const second = line.indexOf(":", first + 1);
        return first < 0 || second < 0 ? "--" : line.slice(first + 1, second);
    }

    function saveBarModules() {
        screenLayouts[activeScreenKey] = barZones;
        const saved = ({ version: 5, screens: screenLayouts, presets: layoutPresets });
        Quickshell.execDetached(["sh", "-c", "mkdir -p \"$HOME/.cache/quickshell\" && printf '%s' '" + JSON.stringify(saved) + "' > \"$HOME/.cache/quickshell/bar-modules.json\""]);
    }

    function cloneZones(zones) { return ({ left: zones.left.slice(), center: zones.center.slice(), right: zones.right.slice() }); }
    function savePreset(name) {
        layoutPresets[name] = cloneZones(barZones);
        saveBarModules();
    }
    function loadPreset(name) {
        const preset = layoutPresets[name];
        if (!preset) return;
        barZones = cloneZones(preset);
        screenLayouts[activeScreenKey] = barZones;
        saveBarModules();
    }

    function loadScreen(key) { activeScreenKey = key; barZones = screenLayouts[key] || barZones; }

    function moveModule(name, screenKey, fromZone, toZone) {
        if (toZone === undefined) { toZone = fromZone; fromZone = screenKey; screenKey = activeScreenKey; }
        if (fromZone === toZone) return;
        const current = screenLayouts[screenKey] || barZones;
        const next = ({ left: current.left.slice(), center: current.center.slice(), right: current.right.slice() });
        const sourceIndex = next[fromZone].indexOf(name);
        if (sourceIndex < 0) return;
        next[fromZone].splice(sourceIndex, 1);
        next[toZone].push(name);
        screenLayouts[screenKey] = next;
        if (activeScreenKey === screenKey) barZones = next;
    }

    function removeModule(name, screenKey, zone) {
        if (zone === undefined) { zone = screenKey; screenKey = activeScreenKey; }
        const current = screenLayouts[screenKey] || barZones;
        const next = ({ left: current.left.slice(), center: current.center.slice(), right: current.right.slice() });
        const index = next[zone].indexOf(name);
        if (index >= 0) next[zone].splice(index, 1);
        screenLayouts[screenKey] = next;
        if (activeScreenKey === screenKey) barZones = next;
    }

    function removeModuleEverywhere(name) {
        ["primary", "secondary"].forEach(key => {
            const current = screenLayouts[key] || ({ left: [], center: [], right: [] });
            screenLayouts[key] = ({ left: current.left.filter(item => item !== name), center: current.center.filter(item => item !== name), right: current.right.filter(item => item !== name) });
        });
        barZones = screenLayouts[activeScreenKey];
        saveBarModules();
    }

    function hasModule(name) { return barZones.left.indexOf(name) >= 0 || barZones.center.indexOf(name) >= 0 || barZones.right.indexOf(name) >= 0 }
    function addModule(name) { if (!hasModule(name)) barZones = ({ left: barZones.left, center: barZones.center.concat([name]), right: barZones.right }); }

    function dropModule(name, screenKey, fromZone, point) {
        if (point === undefined) { point = fromZone; fromZone = screenKey; screenKey = activeScreenKey; }
        const targetZone = point.x < layoutEditor.width / 3 ? "left" : point.x > layoutEditor.width * 2 / 3 ? "right" : "center";
        moveModule(name, screenKey, fromZone, targetZone);
    }

    function resetBarZones() {
        const defaults = ({ left: ["user", "media", "workspaces"], center: ["clock", "audio"], right: ["network", "settings"] });
        screenLayouts = ({ primary: cloneZones(defaults), secondary: cloneZones(defaults) });
        barZones = cloneZones(screenLayouts[activeScreenKey]);
        saveBarModules();
    }

    function migrateZones(saved) { const all = ["user", "media", "workspaces", "clock", "audio", "network", "settings"]; const next = ({ left: saved.left.slice(), center: saved.center.slice(), right: saved.right.slice() }); all.forEach(name => { if (next.left.indexOf(name) < 0 && next.center.indexOf(name) < 0 && next.right.indexOf(name) < 0) next.left.push(name); }); next.version = 3; return next }

    function setVolume(value) {
        const next = Math.max(0, Math.min(1, value));
        panel.volumeLevel = next;
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", next.toFixed(2)]);
    }

    function close() {
        if (closing) return;
        closing = true;
        closeAnimation.start();
    }
}
