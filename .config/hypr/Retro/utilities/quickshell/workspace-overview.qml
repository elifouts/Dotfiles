import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "./theme" as RetroTheme

PanelWindow {
    id: overview
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-workspace-overview"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: "transparent"

    property var workspaceModel: buildWorkspaceModel()

    function buildWorkspaceModel() {
        var result = [];
        for (var id = 1; id <= 10; id++) {
            var windows = Hyprland.toplevels.values.filter(function(window) {
                return window.workspace?.id === id;
            });
            if (windows.length > 0)
                result.push({ id: id, windows: windows });
        }
        return result;
    }

    function workspaceColumns() { return panel.vertical ? 3 : 2; }
    function workspaceCardHeight(windowCount) { return Math.min(panel.vertical ? 620 : 560, 190 + Math.ceil(windowCount / workspaceColumns()) * 158); }
    function gridCellHeight() {
        var maxHeight = panel.vertical ? 430 : 338;
        workspaceModel.forEach(function(workspace) { maxHeight = Math.max(maxHeight, workspaceCardHeight(workspace.windows.length) + 18); });
        return maxHeight;
    }

    function focusWorkspace(id) {
        var workspace = Hyprland.workspaces.values.find(item => item.id === id);
        if (workspace)
            workspace.activate();
        closeAnimation.start();
    }

    function focusWindow(window) {
        if (window.workspace)
            window.workspace.activate();
        closeAnimation.start();
    }

    function closeWindow(window) {
        if (window?.wayland)
            window.wayland.close();
        refreshTimer.restart();
    }

    function removeWorkspace(workspace) {
        if (!workspace)
            return;
        workspace.toplevels.values.slice().forEach(function(window) {
            if (window.wayland)
                window.wayland.close();
        });
        refreshTimer.restart();
    }

    Timer { id: refreshTimer; interval: 500; onTriggered: overview.workspaceModel = overview.buildWorkspaceModel() }

    MouseArea {
        anchors.fill: parent
        z: -10
        acceptedButtons: Qt.LeftButton
        onClicked: closeAnimation.start()
    }

    Item {
        id: panel
        width: Math.min(1180, parent.width - 96)
        height: Math.min(720, parent.height - 112)
        anchors.centerIn: parent
        readonly property bool vertical: height > width
        clip: true
        scale: 0.82
        y: 42
        opacity: 0
        Rectangle {
            anchors.fill: parent
            z: -2
            color: "#d91d2021"
            border.color: RetroTheme.Theme.border
            border.width: 1
            radius: 8
        }
        Component.onCompleted: openAnimation.start()
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

        SequentialAnimation {
            id: openAnimation
            ParallelAnimation {
                NumberAnimation { target: panel; property: "opacity"; to: 1; duration: 180; easing.type: Easing.OutCubic }
                NumberAnimation { target: panel; property: "scale"; to: 1; duration: 520; easing.type: Easing.OutBack }
                NumberAnimation { target: panel; property: "y"; to: 0; duration: 420; easing.type: Easing.OutElastic }
            }
        }

        SequentialAnimation {
            id: closeAnimation
            ParallelAnimation {
                NumberAnimation { target: panel; property: "opacity"; to: 0; duration: 150; easing.type: Easing.InCubic }
                NumberAnimation { target: panel; property: "scale"; to: 0.88; duration: 260; easing.type: Easing.InBack }
                NumberAnimation { target: panel; property: "y"; to: 28; duration: 220; easing.type: Easing.InCubic }
            }
            onFinished: Qt.quit()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 26
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                z: 5
                Text { text: "// WORKSPACE CAST"; color: RetroTheme.Theme.accent; font.family: "JetBrains Mono"; font.pixelSize: 21; font.bold: true }
                Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignRight; text: "ALT+TAB  ESC CLOSE"; color: RetroTheme.Theme.muted; font.family: "JetBrains Mono"; font.pixelSize: 11 }
            }
            Text { z: 5; text: "LIVE WINDOWS  //  CLICK A CARD TO ENTER  //  × CLOSES"; color: RetroTheme.Theme.green; font.family: "JetBrains Mono"; font.pixelSize: 11 }

            GridView {
                id: workspaceGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: panel.vertical ? width : width / 2
                cellHeight: overview.gridCellHeight()
                model: overview.workspaceModel
                z: 1
                delegate: Rectangle {
                    id: card
                    required property var modelData
                    required property int index
                    property bool hovered: workspaceMouse.containsMouse
                    width: workspaceGrid.cellWidth - 14
                    height: overview.workspaceCardHeight(modelData.windows.length)
                    border.width: 1
                    radius: 5
                    clip: true
                    opacity: 0
                    rotation: index % 2 === 0 ? -0.45 : 0.45
                    y: 0
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 3
                        z: -1
                        color: "transparent"
                        border.color: modelData.id === (Hyprland.focusedWorkspace?.id ?? 1) ? RetroTheme.Theme.accent : RetroTheme.Theme.accentAlt
                        border.width: 1
                        radius: 4
                        opacity: card.opacity * 0.38
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.12; duration: 720 + index * 55; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 0.38; duration: 720 + index * 55; easing.type: Easing.InOutSine }
                        }
                    }
                    Component.onCompleted: enter.start()
                    color: hovered ? RetroTheme.Theme.surfaceAlt : RetroTheme.Theme.surface
                    border.color: hovered ? RetroTheme.Theme.accentAlt : modelData.id === (Hyprland.focusedWorkspace?.id ?? 1) ? RetroTheme.Theme.accent : RetroTheme.Theme.border
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                    scale: hovered ? 1.015 : 1
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                    SequentialAnimation {
                        id: enter
                        PauseAnimation { duration: index * 72 }
                        ParallelAnimation {
                            NumberAnimation { target: card; property: "opacity"; to: 1; duration: 260; easing.type: Easing.OutCubic }
                            NumberAnimation { target: card; property: "scale"; to: 1; duration: 480; easing.type: Easing.OutBack }
                            NumberAnimation { target: card; property: "rotation"; to: 0; duration: 420; easing.type: Easing.OutElastic }
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12
                        z: 1
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "WS " + String(modelData.id).padStart(2, "0"); color: modelData.id === (Hyprland.focusedWorkspace?.id ?? 1) ? RetroTheme.Theme.accent : RetroTheme.Theme.foreground; font.family: "JetBrains Mono"; font.pixelSize: 16; font.bold: true }
                            Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignRight; text: modelData.windows.length + " WINDOWS"; color: RetroTheme.Theme.muted; font.family: "JetBrains Mono"; font.pixelSize: 9 }
                            Rectangle { z: 10; width: 28; height: 28; radius: 14; color: removeWorkspaceMouse.containsMouse ? RetroTheme.Theme.red : RetroTheme.Theme.background; border.color: RetroTheme.Theme.border; Text { anchors.centerIn: parent; text: "×"; color: RetroTheme.Theme.foreground; font.pixelSize: 16 } MouseArea { id: removeWorkspaceMouse; anchors.fill: parent; acceptedButtons: Qt.LeftButton; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: overview.removeWorkspace(Hyprland.workspaces.values.find(item => item.id === modelData.id)) } }
                        }
                        Flow {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 6
                            Repeater {
                                model: modelData.windows
                                delegate: Rectangle {
                                    required property var modelData
                                    width: Math.min(300, (workspaceGrid.cellWidth - (panel.vertical ? 76 : 62)) / overview.workspaceColumns())
                                    height: 146
                                    color: RetroTheme.Theme.background
                                    border.color: RetroTheme.Theme.border
                                    border.width: 1
                                    radius: 3
                                    clip: true
                                    ScreencopyView { anchors.fill: parent; anchors.margins: 4; captureSource: modelData.wayland; live: true; constraintSize: Qt.size(parent.width - 8, parent.height - 8) }
                                    Rectangle { anchors.fill: parent; anchors.margins: 2; color: "transparent"; border.color: RetroTheme.Theme.accentAlt; border.width: 1; radius: 2 }
                                    Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 22; color: "#cc1d2021"; Text { anchors.fill: parent; anchors.margins: 5; text: modelData.title || "WINDOW"; color: RetroTheme.Theme.foreground; font.family: "JetBrains Mono"; font.pixelSize: 9; elide: Text.ElideRight } }
                                    Rectangle { anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 5; width: 28; height: 28; radius: 14; color: closeMouse.containsMouse ? RetroTheme.Theme.red : "#cc1d2021"; border.color: RetroTheme.Theme.border; border.width: 1; z: 10; Text { anchors.centerIn: parent; text: "×"; color: RetroTheme.Theme.foreground; font.pixelSize: 15 } MouseArea { id: closeMouse; anchors.fill: parent; acceptedButtons: Qt.LeftButton; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: overview.closeWindow(modelData) } }
                                }
                            }
                        }
                    }
                    MouseArea { id: workspaceMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; z: -1; onClicked: overview.focusWorkspace(modelData.id) }
                }
            }
        }

        Shortcut { sequence: "Escape"; onActivated: closeAnimation.start() }
    }
}
