pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property int users: 0
    readonly property int bars: 36
    readonly property var levels: feed.levels

    CavaFeed { id: feed; running: root.users > 0; bars: root.bars }
}
