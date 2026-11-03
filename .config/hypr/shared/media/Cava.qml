pragma Singleton

import QtQuick
import Quickshell

// one cava for every visualizer, each monitor's bar used to spawn its own
Singleton {
    id: root

    property int users: 0
    readonly property int bars: 36
    readonly property var levels: feed.levels

    CavaFeed { id: feed; running: root.users > 0; bars: root.bars }
}
