import QtQuick

// keeps the osd card off media screens
QtObject {
    property bool on: false
    property bool counted: false
    function sync() {
        if (on === counted) return
        counted = on
        Media.views += on ? 1 : -1
    }
    onOnChanged: sync()
    Component.onCompleted: sync()
    Component.onDestruction: if (counted) Media.views--
}
