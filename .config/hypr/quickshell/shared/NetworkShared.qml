import QtQuick

Grid {
    id: menu

    property bool open: false
    signal run(string cmd)

    readonly property bool holdOpen: wifi.holdOpen
    readonly property real colW: columns === 2 ? (width - columnSpacing) / 2 : width

    columns: width >= 600 ? 2 : 1
    columnSpacing: 22
    rowSpacing: 18

    WifiShared {
        id: wifi
        width: menu.colW
        open: menu.open
        onRun: c => menu.run(c)
    }

    BluetoothListShared {
        width: menu.colW
        open: menu.open
    }
}
