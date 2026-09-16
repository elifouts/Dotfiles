import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "./theme" as RetroTheme

PanelWindow {
    id: picker
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: "transparent"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    property bool closing: false
    property string filter: "all"
    property int page: 0
    readonly property int pageSize: 12
    readonly property var categories: ["all", "animated", "nature", "urban", "landscape", "plants", "abstract", "personal"]
    readonly property var pywalColors: [RetroTheme.Theme.accent, RetroTheme.Theme.blue, RetroTheme.Theme.purple, RetroTheme.Theme.green, RetroTheme.Theme.orange, RetroTheme.Theme.red, RetroTheme.Theme.accentAlt]
    property var visibleWallpapers: wallpapers.filter(path => filter === "all" || categoryFor(path) === filter)
    property var pagedWallpapers: visibleWallpapers.slice(page * pageSize, (page + 1) * pageSize)
    property var preloadWallpapers: visibleWallpapers.slice((page + 1) * pageSize, (page + 2) * pageSize)
    readonly property int pageCount: Math.max(1, Math.ceil(visibleWallpapers.length / pageSize))

    MouseArea { anchors.fill: parent; onClicked: if (!card.containsMouse) picker.close() }
    property var wallpapers: []

    Process {
        command: ["sh", "-c", "find \"$HOME/wallpapers/walls\" \"$HOME/wallpapers/wallpapers\" -type f ! -path '*/.git/*' \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.webp' \\) | sort -u"]
        running: true
        stdout: StdioCollector { onStreamFinished: picker.wallpapers = picker.shufflePaths(this.text.trim().split("\n").filter(path => path.length > 0)) }
    }

    Rectangle {
        id: card
        width: Math.min(920, picker.width - 48)
        height: Math.min(720, picker.height - 64)
        anchors.centerIn: parent
        color: RetroTheme.Theme.surface
        border.color: RetroTheme.Theme.accent
        border.width: 2
        Column {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 14
            Rectangle { id: paletteRail; width: parent.width; height: 2; color: RetroTheme.Theme.border; Rectangle { width: paletteRail.width * 0.42; height: paletteRail.height; color: RetroTheme.Theme.accent; SequentialAnimation on x { loops: Animation.Infinite; NumberAnimation { to: paletteRail.width * 0.58; duration: 1400; easing.type: Easing.InOutSine } NumberAnimation { to: 0; duration: 1200; easing.type: Easing.InOutSine } } } }
            RowLayout {
                width: parent.width
                Text { text: "// WALLPAPER MATRIX"; color: RetroTheme.Theme.accent; font.family: "JetBrains Mono"; font.pixelSize: 19; font.bold: true }
                Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignRight; text: picker.visibleWallpapers.length + " SIGNALS"; color: RetroTheme.Theme.muted; font.family: "JetBrains Mono"; font.pixelSize: 12 }
            }
            Row {
                width: parent.width
                spacing: 6
                Repeater {
                    model: picker.categories
                    Rectangle {
                        required property string modelData
                        width: categoryLabel.implicitWidth + 18
                        height: 26
                        radius: 7
                        color: picker.filter === modelData ? RetroTheme.Theme.accent : categoryMouse.containsMouse ? RetroTheme.Theme.surfaceAlt : RetroTheme.Theme.background
                        border.color: picker.filter === modelData ? RetroTheme.Theme.accent : RetroTheme.Theme.border
                        scale: categoryMouse.containsMouse ? 1.04 : 1
                        Text { id: categoryLabel; anchors.centerIn: parent; text: modelData.toUpperCase(); color: picker.filter === modelData ? RetroTheme.Theme.background : RetroTheme.Theme.muted; font.family: "JetBrains Mono"; font.pixelSize: 9; font.bold: true }
                        MouseArea { id: categoryMouse; anchors.fill: parent; hoverEnabled: true; onClicked: picker.setFilter(modelData) }
                        Behavior on color { ColorAnimation { duration: 130 } }
                        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutBack } }
                    }
                }
            }
            GridView {
                width: parent.width
                height: parent.height - 150
                clip: true
                interactive: true
                boundsBehavior: Flickable.StopAtBounds
                WheelHandler { id: pageWheel; orientation: Qt.Vertical; onWheel: function(event) { if (event.angleDelta.y < 0) picker.nextPage(); else if (event.angleDelta.y > 0) picker.previousPage(); event.accepted = true } }
                cellWidth: 210
                cellHeight: 142
                cacheBuffer: 142
                model: picker.pagedWallpapers
                populate: Transition { NumberAnimation { properties: "opacity,scale"; from: 0.35; to: 1; duration: 260; easing.type: Easing.OutCubic } }
                add: Transition { NumberAnimation { properties: "opacity,scale"; from: 0.2; to: 1; duration: 240; easing.type: Easing.OutCubic } }
                displaced: Transition { NumberAnimation { properties: "x,y"; duration: 260; easing.type: Easing.OutBack } }
                delegate: Rectangle {
                    required property string modelData
                    required property int index
                    width: 198
                    height: 130
                    property color imageAccent: picker.pywalColors[index % picker.pywalColors.length]
                    property bool hovered: hover.containsMouse
                    color: hovered ? RetroTheme.Theme.surfaceAlt : RetroTheme.Theme.background
                    border.color: hovered ? imageAccent : Qt.darker(imageAccent, 1.8)
                    border.width: 1
                    scale: hovered ? 1.035 : 1
                    Behavior on color { ColorAnimation { duration: 110 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                    Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                    Image {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 6
                        height: 92
                        source: "file://" + parent.modelData
                        asynchronous: true
                        cache: true
                        sourceSize: Qt.size(320, 150)
                        fillMode: Image.PreserveAspectCrop
                        clip: true
                        opacity: status === Image.Ready ? 1 : 0.25
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                    }
                    Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; height: 3; color: imageAccent; opacity: hovered ? 1 : 0.65; Behavior on opacity { NumberAnimation { duration: 160 } } }
                    Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 26; color: RetroTheme.Theme.background }
                    Text { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.leftMargin: 9; anchors.bottomMargin: 6; text: parent.modelData.split('/').pop(); color: RetroTheme.Theme.foreground; font.family: "JetBrains Mono"; font.pixelSize: 11; elide: Text.ElideMiddle }
                    MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/utilities/wallpaper.sh", parent.modelData]); picker.close() } }
                }
            }
            Repeater { model: picker.preloadWallpapers; delegate: Image { required property string modelData; width: 1; height: 1; opacity: 0; asynchronous: true; cache: true; sourceSize: Qt.size(320, 150); source: "file://" + modelData } }
            RowLayout {
                width: parent.width
                height: 28
                Text { text: "PAGE " + (picker.page + 1) + " / " + picker.pageCount; color: RetroTheme.Theme.muted; font.family: "JetBrains Mono"; font.pixelSize: 10 }
                Item { Layout.fillWidth: true }
                Rectangle { width: 28; height: 24; radius: 6; color: picker.page > 0 ? RetroTheme.Theme.background : RetroTheme.Theme.surface; border.color: RetroTheme.Theme.border; Text { anchors.centerIn: parent; text: "‹"; color: RetroTheme.Theme.foreground; font.pixelSize: 17 } MouseArea { anchors.fill: parent; enabled: picker.page > 0; onClicked: picker.previousPage() } }
                Rectangle { width: 28; height: 24; radius: 6; color: picker.page + 1 < picker.pageCount ? RetroTheme.Theme.background : RetroTheme.Theme.surface; border.color: RetroTheme.Theme.border; Text { anchors.centerIn: parent; text: "›"; color: RetroTheme.Theme.foreground; font.pixelSize: 17 } MouseArea { anchors.fill: parent; enabled: picker.page + 1 < picker.pageCount; onClicked: picker.nextPage() } }
            }
        }
        opacity: 0
        scale: 0.96
        Component.onCompleted: openAnimation.start()
        ParallelAnimation {
            id: openAnimation
            NumberAnimation { target: card; property: "opacity"; to: 1; duration: 150; easing.type: Easing.OutCubic }
            NumberAnimation { target: card; property: "scale"; to: 1; duration: 250; easing.type: Easing.OutBack }
        }
        ParallelAnimation {
            id: closeAnimation
            NumberAnimation { target: card; property: "opacity"; to: 0; duration: 110; easing.type: Easing.InCubic }
            NumberAnimation { target: card; property: "scale"; to: 0.96; duration: 150; easing.type: Easing.InCubic }
            onFinished: Qt.quit()
        }
        Keys.onEscapePressed: picker.close()
        focus: true
    }

    function close() {
        if (closing) return;
        closing = true;
        closeAnimation.start();
    }

    function categoryFor(path) {
        const normalized = path.toLowerCase();
        if (normalized.includes("/animated/") || normalized.endsWith(".gif")) return "animated";
        if (normalized.includes("/nature/") || normalized.includes("/forest/")) return "nature";
        if (normalized.includes("/urban/") || normalized.includes("/cars/")) return "urban";
        if (normalized.includes("/landscape/") || normalized.includes("/sunset/")) return "landscape";
        if (normalized.includes("/plants/")) return "plants";
        if (normalized.includes("/stuff-i-made/")) return "personal";
        return "abstract";
    }

    function setFilter(nextFilter) {
        filter = nextFilter;
        page = 0;
    }

    function nextPage() { page = Math.min(page + 1, pageCount - 1); }
    function previousPage() { page = Math.max(0, page - 1); }

    function shufflePaths(paths) {
        const shuffled = paths.slice();
        for (let index = shuffled.length - 1; index > 0; index--) {
            const swapIndex = Math.floor(Math.random() * (index + 1));
            const item = shuffled[index];
            shuffled[index] = shuffled[swapIndex];
            shuffled[swapIndex] = item;
        }
        return shuffled;
    }
}
