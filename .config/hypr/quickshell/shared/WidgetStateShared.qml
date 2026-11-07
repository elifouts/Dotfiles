pragma Singleton

import QtQuick
import Quickshell

Singleton {
    property string editing: ""
    property string typing: ""
    function toggle() { editing = editing ? "" : HyprShared.focusedScreen()?.name ?? "" }
}
