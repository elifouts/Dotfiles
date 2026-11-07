import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../style/common"

Item {
    id: page

    property bool active: false
    property bool open: false
    property string kind: "shot"
    property int elapsed: 0
    signal done()

    readonly property string dir: HyprShared.dir + "/quickshell/shared/capture/"
    function capture(kind, mode) {
        done()
        HyprShared.run("sleep 0.35; '" + dir + (kind === "share" ? "share.sh' pick " : "capture.sh' " + kind + " ") + mode)
    }
    function stop() { HyprShared.run("'" + dir + "capture.sh' stop") }
    function cancelShare() { HyprShared.run("'" + dir + "share.sh' cancel") }
    function cast(tv, mode) {
        done()
        Quickshell.execDetached(["sh", "-c", 'sleep 0.35; exec "$0" start "$1" "$2" "$3" "$4"', dir + "cast.py", tv.kind, tv.target, tv.name, mode])
    }
    function stopCast() { Quickshell.execDetached([dir + "cast.py", "stop"]) }

    property var tvs: []
    property var tv: null
    property bool scanned: false
    onKindChanged: { tv = null; if (kind !== "cast") { tvs = []; scanned = false } }
    Process {
        id: scanner
        command: [page.dir + "cast.py", "scan"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { page.tvs = JSON.parse(text) } catch (e) {}
                page.scanned = true
            }
        }
    }
    Timer {
        running: page.kind === "cast" && !page.tv && page.active && !page.casting
        interval: 6000
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!scanner.running) scanner.running = true
    }

    WatchedShared {
        id: castFile
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/cast-state"
    }
    readonly property var castState: { try { return JSON.parse(castFile.text()) } catch (e) { return null } }
    readonly property bool casting: !!castState
    readonly property int castStarted: casting ? castState.started : 0

    WatchedShared {
        id: shareReq
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/share-request"
    }
    readonly property bool sharing: shareReq.text() !== ""
    property bool picked: false
    onSharingChanged: { picked = false; kind = sharing ? "share" : kind === "share" ? "shot" : kind }
    onOpenChanged: if (!open && sharing && !picked) cancelShare()

    WatchedShared {
        id: state
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/capture-rec"
    }
    readonly property int started: parseInt(state.text()) || 0
    readonly property bool recording: started > 0

    readonly property int since: recording ? started : castStarted
    function tick() { elapsed = Math.max(0, Math.floor(Date.now() / 1000) - since) }
    onSinceChanged: tick()
    Timer { running: page.since > 0 && page.active; interval: 1000; repeat: true; triggeredOnStart: true; onTriggered: page.tick() }

    function clock(s) {
        const p = n => String(n).padStart(2, "0")
        return p(Math.floor(s / 60)) + ":" + p(s % 60)
    }

    Column {
        width: parent.width
        anchors.centerIn: parent
        spacing: 14
        visible: !page.recording && !page.casting

        Row {
            visible: !page.tv
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6

            Repeater {
                model: [{ id: "shot", label: "󰄀  Photo" }, { id: "rec", label: "󰻃  Video" }, { id: "cast", label: "󰄘  Cast" }]
                    .concat(page.sharing ? [{ id: "share", label: "󰹑  Share" }] : [])

                Button {
                    required property var modelData
                    primary: page.kind === modelData.id
                    label: modelData.label
                    onPressed: page.kind = modelData.id === "cast" && page.kind === "cast" ? "shot" : modelData.id
                }
            }
        }

        Item {
            visible: !!page.tv
            width: parent.width
            height: 32

            Button {
                id: backBtn
                label: "\uf053"
                onPressed: page.tv = null
            }
            LabelShared {
                anchors.left: backBtn.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: page.tv ? "󰄘  " + page.tv.name : ""
                elide: Text.ElideRight
                font.pixelSize: 14
                color: Theme.bright
            }
        }

        ClippingRectangle {
            visible: page.kind === "cast" && !page.tv
            width: parent.width
            height: 108
            radius: Math.min(Theme.rounding, 12)
            color: Theme.alpha(Theme.fg, 0.055)
            border.width: Theme.lines
            border.color: Theme.edge

            Flickable {
                anchors.fill: parent
                contentHeight: tvList.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: tvList
                    width: parent.width

                    Repeater {
                        model: page.tvs

                        Rectangle {
                            id: tvRow
                            required property var modelData
                            width: tvList.width
                            height: 34
                            color: Theme.alpha(Theme.fg, tvArea.containsMouse ? 0.1 : 0)
                            Behavior on color { ColorAnimation { duration: Theme.fast } }

                            LabelShared {
                                anchors.left: parent.left
                                anchors.leftMargin: 16
                                anchors.right: parent.right
                                anchors.rightMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                text: (tvRow.modelData.kind === "cast" ? "󰄘" : tvRow.modelData.kind === "dlna" ? "󰔂" : "󰖩") + "   " + tvRow.modelData.name
                                elide: Text.ElideRight
                                font.pixelSize: 12
                                color: tvArea.containsMouse ? Theme.bright : Theme.fg
                            }

                            HoverShared {
                                id: tvArea
                                anchors.fill: parent
                                onClicked: page.tv = tvRow.modelData
                            }
                        }
                    }
                }
            }

            LabelShared {
                id: searching
                visible: page.tvs.length === 0
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.top: parent.top
                anchors.topMargin: 13
                text: scanner.running || !page.scanned ? "Searching…" : "No TVs"
                font.pixelSize: 11
                font.capitalization: Theme.caps
                font.letterSpacing: Theme.tracking
                color: Theme.dim
                SequentialAnimation on opacity {
                    running: scanner.running && page.active
                    loops: Animation.Infinite
                    onRunningChanged: if (!running) searching.opacity = 1
                    NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
                }
            }
        }

        Row {
            id: tiles
            visible: page.kind !== "cast" || !!page.tv
            width: parent.width
            spacing: 8

            Repeater {
                model: [{ id: "region", glyph: "󰆞", label: "Region" }, { id: "window", glyph: "󱂬", label: "Window" }, { id: "screen", glyph: "󰍹", label: "Screen" }]

                Rectangle {
                    id: tile
                    required property var modelData
                    width: (tiles.width - tiles.spacing * 2) / 3
                    height: 72
                    radius: Math.min(Theme.rounding, 12)
                    border.width: Theme.lines
                    border.color: tileArea.containsMouse ? Theme.accent : Theme.edge
                    color: Theme.alpha(Theme.fg, tileArea.containsMouse ? 0.12 : 0.055)
                    scale: tileArea.pressed ? 0.95 : 1
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                    Behavior on scale { NumberAnimation { duration: Theme.ms(120) } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 5
                        LabelShared {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.modelData.glyph
                            font.pixelSize: 20
                            color: tileArea.containsMouse ? Theme.accent : Theme.fg
                        }
                        LabelShared {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.modelData.label
                            font.pixelSize: 10
                            font.capitalization: Theme.caps
                            font.letterSpacing: Theme.tracking
                            color: Theme.dim
                        }
                    }

                    HoverShared {
                        id: tileArea
                        anchors.fill: parent
                        onClicked: {
                            if (page.kind === "cast") { page.cast(page.tv, tile.modelData.id); page.tv = null; return }
                            if (page.kind === "share") page.picked = true
                            page.capture(page.kind, tile.modelData.id)
                        }
                    }
                }
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 10
        visible: page.recording || page.casting

        LabelShared {
            visible: !page.recording
            anchors.horizontalCenter: parent.horizontalCenter
            text: "󰄘  " + (page.castState ? page.castState.name : "")
            font.pixelSize: 13
            color: Theme.fg
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            Rectangle {
                visible: page.recording
                anchors.verticalCenter: parent.verticalCenter
                width: 10
                height: 10
                radius: Theme.round * 5
                color: Theme.warn
                SequentialAnimation on opacity {
                    running: page.recording && page.active
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.25; duration: 700 }
                    NumberAnimation { to: 1; duration: 700 }
                }
            }
            LabelShared {
                text: page.since > 0 ? page.clock(page.elapsed) : "Connecting…"
                font.pixelSize: page.since > 0 ? 28 : 18
                font.bold: true
                color: Theme.bright
            }
        }

        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            primary: true
            label: "󰓛  Stop"
            onPressed: page.recording ? page.stop() : page.stopCast()
        }
    }
}
