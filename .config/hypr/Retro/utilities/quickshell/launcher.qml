import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "./theme" as RetroTheme

PanelWindow {
    id: launcher
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-panel"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: "transparent"
    property var applications: []
    property string query: ""
    property bool closing: false

    Process {
        command: ["sh", "-c", "cache=\"${XDG_CACHE_HOME:-$HOME/.cache}/hypr/launcher-apps-v2.tsv\"; if [ -s \"$cache\" ]; then cat \"$cache\"; else find \"$HOME/.local/share/applications\" /usr/share/applications -type f -name '*.desktop' 2>/dev/null | sort -u | while read -r f; do if grep -qE '^(NoDisplay|Hidden)=true' \"$f\"; then continue; fi; name=$(grep -m1 '^Name=' \"$f\" | cut -d= -f2-); exec=$(grep -m1 '^Exec=' \"$f\" | cut -d= -f2- | sed 's/ %[fFuUdDnNickvm]//g'); icon=$(grep -m1 '^Icon=' \"$f\" | cut -d= -f2-); [ -n \"$name\" ] && [ -n \"$exec\" ] && printf '%s\\t%s\\t%s\\n' \"$name\" \"$exec\" \"$icon\"; done; fi"]
        running: true
        stdout: StdioCollector { onStreamFinished: {
            launcher.applications = this.text.trim().split("\n").filter(line => line.length).map(line => {
                const parts = line.split("\t");
                return { name: parts[0], exec: parts[1], icon: parts[2] || "application-x-executable", rank: launcher.commonRank(parts[0]) };
            });
            launcher.applications.sort((a, b) => a.rank - b.rank || a.name.localeCompare(b.name));
        } }
    }

    property var filteredApplications: applications
        .filter(app => query.trim() === "" || app.name.toLowerCase().includes(query.toLowerCase()))
        .sort((a, b) => launcher.resultRank(a) - launcher.resultRank(b) || a.name.localeCompare(b.name))

    function commonRank(name) {
        const common = ["Firefox", "Kitty", "Terminal", "Files", "Steam", "Spotify", "Visual Studio Code", "Thunar", "Dolphin", "Discord", "Code", "Chromium"];
        const index = common.findIndex(item => name.toLowerCase().includes(item.toLowerCase()));
        return index < 0 ? 100 : index;
    }

    function resultRank(app) {
        const needle = query.trim().toLowerCase();
        if (!needle) return app.rank;
        const name = app.name.toLowerCase();
        if (name === needle) return -30;
        if (name.startsWith(needle)) return -20;
        return app.rank;
    }

    Rectangle {
        id: panel
        width: Math.max(0, Math.min(640, launcher.width - 48))
        height: Math.max(0, Math.min(540, launcher.height - 96))
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(52, (launcher.height - height) / 2)
        color: RetroTheme.Theme.surface
        border.color: RetroTheme.Theme.border
        border.width: 1
        radius: 12
        scale: 1
        opacity: 0
        Component.onCompleted: openAnimation.start()
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
        ParallelAnimation {
            id: openAnimation
            NumberAnimation { target: panel; property: "opacity"; to: 1; duration: 140; easing.type: Easing.OutCubic }
        }
        ParallelAnimation {
            id: closeAnimation
            NumberAnimation { target: panel; property: "opacity"; to: 0; duration: 110; easing.type: Easing.InCubic }
            onFinished: Qt.quit()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 16
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Applications"; color: RetroTheme.Theme.foreground; font.family: "Cantarell"; font.pixelSize: 19; font.bold: true }
                Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignRight; text: launcher.filteredApplications.length; color: RetroTheme.Theme.muted; font.family: "Cantarell"; font.pixelSize: 12 }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                color: RetroTheme.Theme.background
                border.color: search.activeFocus ? RetroTheme.Theme.accent : RetroTheme.Theme.border
                border.width: 1
                radius: 9
                Text { anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter; text: "⌕"; color: RetroTheme.Theme.muted; font.family: "Cantarell"; font.pixelSize: 21 }
                TextInput {
                    id: search
                    anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 38; anchors.rightMargin: 12
                    focus: true
                    color: RetroTheme.Theme.foreground
                    font.family: "Cantarell"
                    font.pixelSize: 14
                    onTextChanged: launcher.query = text
                    Text { visible: !search.text; anchors.verticalCenter: parent.verticalCenter; text: "Search applications"; color: RetroTheme.Theme.muted; font: search.font }
                    Keys.onEscapePressed: launcher.close()
                    Keys.onDownPressed: appList.currentIndex = Math.min(appList.count - 1, appList.currentIndex + 1)
                    Keys.onUpPressed: appList.currentIndex = Math.max(0, appList.currentIndex - 1)
                    Keys.onRightPressed: appList.currentIndex = Math.min(appList.count - 1, appList.currentIndex + 1)
                    Keys.onLeftPressed: appList.currentIndex = Math.max(0, appList.currentIndex - 1)
                    Keys.onReturnPressed: launch(appList.currentItem ? appList.currentItem.app : launcher.filteredApplications[0])
                }
            }
            GridView {
                id: appList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: 96
                cellHeight: 96
                leftMargin: Math.max(0, (width - Math.floor(width / cellWidth) * cellWidth) / 2)
                rightMargin: leftMargin
                model: launcher.filteredApplications
                currentIndex: 0
                delegate: Rectangle {
                    required property var modelData
                    property var app: modelData
                    width: 84
                    height: 86
                    property bool hovered: itemHover.containsMouse
                    color: GridView.isCurrentItem || hovered ? RetroTheme.Theme.surfaceAlt : "transparent"
                    border.color: GridView.isCurrentItem ? RetroTheme.Theme.accent : hovered ? RetroTheme.Theme.border : "transparent"
                    border.width: 1
                    radius: 9
                    Behavior on color { ColorAnimation { duration: 110 } }
                    Behavior on border.color { ColorAnimation { duration: 110 } }
                    scale: hovered ? 1.04 : 1
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Image { anchors.top: parent.top; anchors.topMargin: 7; anchors.horizontalCenter: parent.horizontalCenter; width: 48; height: 48; source: parent.app.icon && parent.app.icon.startsWith("/") ? "file://" + parent.app.icon : Quickshell.iconPath(parent.app.icon || "application-x-executable-symbolic", "application-x-executable-symbolic"); asynchronous: true; cache: true; fillMode: Image.PreserveAspectFit }
                    Text { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.bottomMargin: 7; text: parent.app.name; color: GridView.isCurrentItem ? RetroTheme.Theme.foreground : RetroTheme.Theme.muted; font.family: "Cantarell"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; maximumLineCount: 2; wrapMode: Text.Wrap; elide: Text.ElideRight }
                    MouseArea { id: itemHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: launch(parent.app) }
                }
            }
        }
    }

    function launch(app) {
        if (!app) return;
        Quickshell.execDetached(["sh", "-c", app.exec]);
        close();
    }

    function close() {
        if (closing) return;
        closing = true;
        closeAnimation.start();
    }
}
