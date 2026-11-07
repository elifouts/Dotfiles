import QtQuick

QtObject {
    property bool on: false
    property bool counted: false
    function sync() {
        if (on === counted) return
        counted = on
        MediaShared.views += on ? 1 : -1
    }
    onOnChanged: sync()
    Component.onCompleted: sync()
    Component.onDestruction: if (counted) MediaShared.views--
}
