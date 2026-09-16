import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "./theme" as RetroTheme

PanelWindow {
    id: osd
    anchors { left: true; right: true; bottom: true }
    implicitHeight: 150
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-osd"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region { item: maskArea }

    property string kind: "volume"
    property string value: "0"
    property string title: "VOLUME"
    property string glyph: "\uf028"
    property string mediaTrack: ""
    property string mediaStatus: ""
    property string mediaArt: ""
    property real progress: 0
    property bool showing: false
    property bool osdEnabled: true

    Process {
        id: stateProcess
        command: ["sh", "-c", "cat \"$HOME/.cache/hypr/osd-state\" 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: {
            if (!osd.osdEnabled) return;
            const fields = this.text.trim().split("\t");
            const parts = fields[0].split(/\s+/);
            if (parts.length < 2) return;
            const nextKind = parts[0];
            const nextValue = parts.slice(1).join(" ");
            osd.kind = nextKind;
            osd.value = nextValue;
            osd.mediaStatus = nextKind === "media" ? (parts[1] || "PAUSED") : "";
            osd.mediaTrack = nextKind === "media" ? parts.slice(2).join(" ") : "";
            osd.mediaArt = nextKind === "media" ? (fields[1] || "") : "";
            osd.title = nextKind === "volume" ? "VOLUME" : nextKind === "brightness" ? "BRIGHTNESS" : nextKind === "media" ? "MEDIA" : nextKind === "caps" ? "CAPS LOCK" : "SYSTEM";
            osd.glyph = nextKind === "volume" ? "\uf028" : nextKind === "brightness" ? "\uf185" : nextKind === "media" ? "\uf144" : nextKind === "caps" ? "\uf11c" : "\uf0eb";
            osd.progress = nextKind === "volume" || nextKind === "brightness" ? Math.max(0, Math.min(1, parseFloat(nextValue) / 100)) : 1;
            osd.showing = true;
            hideTimer.restart();
        } }
    }

    IpcHandler {
        target: "osd"
        function refresh(): void {
            stateProcess.running = false;
            stateProcess.running = true;
        }
        function toggle(): void {
            osd.osdEnabled = !osd.osdEnabled;
            if (!osd.osdEnabled) {
                hideTimer.stop();
                osd.showing = false;
            }
        }
    }

    Timer { id: hideTimer; interval: kind === "media" ? 1700 : 1050; onTriggered: osd.showing = false }

    Item {
        id: maskArea
        anchors.centerIn: card
        width: osd.showing ? card.width : 0
        height: osd.showing ? card.height : 0
    }

    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28
        width: Math.min(440, parent.width - 32)
        height: kind === "media" ? 104 : 82
        radius: 10
        color: RetroTheme.Theme.surface
        border.color: kind === "volume" ? RetroTheme.Theme.purple : kind === "brightness" ? RetroTheme.Theme.orange : kind === "caps" ? (value === "ON" ? RetroTheme.Theme.accent : RetroTheme.Theme.border) : RetroTheme.Theme.accent
        border.width: 1
        opacity: osd.showing ? 1 : 0
        scale: osd.showing ? 1 : 0.94
        y: osd.showing ? 0 : 8
        Behavior on opacity { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Row {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 15
            Item {
                width: 42
                height: 42
                y: (parent.height - height) / 2
                Rectangle {
                    id: artFrame
                    anchors.fill: parent
                    visible: osd.kind === "media" && osd.mediaArt.length > 0
                    radius: 21
                    clip: true
                    color: RetroTheme.Theme.background
                    scale: osd.showing ? 1 : 0.84
                    Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                    Image { anchors.fill: parent; source: osd.mediaArt; asynchronous: true; cache: true; fillMode: Image.PreserveAspectCrop }
                }
                Text {
                    id: iconGlyph
                    visible: osd.kind !== "media" || osd.mediaArt.length === 0
                    anchors.centerIn: parent
                    text: glyph
                    color: card.border.color
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 26
                    transformOrigin: Item.Center
                    onTextChanged: iconChange.restart()
                    SequentialAnimation {
                        id: iconChange
                        ParallelAnimation {
                            NumberAnimation { target: iconGlyph; property: "opacity"; to: 0.35; duration: 70; easing.type: Easing.OutCubic }
                            NumberAnimation { target: iconGlyph; property: "scale"; to: 0.78; duration: 70; easing.type: Easing.OutCubic }
                        }
                        ParallelAnimation {
                            NumberAnimation { target: iconGlyph; property: "opacity"; to: 1; duration: 190; easing.type: Easing.OutCubic }
                            NumberAnimation { target: iconGlyph; property: "scale"; to: 1; duration: 240; easing.type: Easing.OutBack }
                        }
                    }
                }
            }
            Column {
                width: parent.width - 58
                y: (parent.height - height) / 2
                spacing: 8
                Row {
                    width: parent.width
                    spacing: 12
                    Text { text: title; color: RetroTheme.Theme.muted; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true }
                    Text { text: kind === "media" ? mediaStatus : kind === "caps" ? value : value + (kind === "volume" || kind === "brightness" ? "%" : ""); color: RetroTheme.Theme.foreground; font.family: "JetBrains Mono"; font.pixelSize: 15; font.bold: true }
                }
                Text { width: parent.width; visible: kind === "media"; text: mediaTrack; color: RetroTheme.Theme.foreground; font.family: "JetBrains Mono"; font.pixelSize: 13; elide: Text.ElideRight; maximumLineCount: 1 }
                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: RetroTheme.Theme.border
                    visible: kind === "volume" || kind === "brightness"
                    Rectangle { width: parent.width * osd.progress; height: parent.height; radius: 3; color: card.border.color; Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } } }
                }
                Rectangle { width: parent.width; height: 4; radius: 2; visible: kind === "caps"; color: card.border.color; opacity: value === "ON" ? 1 : 0.3; Behavior on opacity { NumberAnimation { duration: 150 } } }
            }
        }
    }
}