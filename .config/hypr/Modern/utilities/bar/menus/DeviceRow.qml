import QtQuick
import Quickshell.Bluetooth
import "../../common"

Entry {
    id: dr
    property var owner
    required property var modelData
    glyph: owner.glyph(modelData)
    label: owner.label(modelData)
    sub: owner.status(modelData)
    height: 40
    trailing: modelData.batteryAvailable ? Math.round((modelData.battery > 1 ? modelData.battery : modelData.battery * 100)) + "%" : ""
    active: modelData.connected
    busy: modelData.pairing || modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
    onClicked: owner.pick(modelData)
    onRightClicked: if (modelData.paired) modelData.forget()

    Component.onCompleted: {
        if (busy) owner.mark(modelData)
        else if (modelData.connected && owner.fresh(modelData)) cheer()
    }
    Connections {
        target: dr
        function onBusyChanged() { if (dr.busy) dr.owner.mark(dr.modelData) }
    }
    Connections {
        target: dr.modelData
        function onPairedChanged() {
            if (dr.modelData.paired && owner.pending[dr.modelData.address]) {
                owner.pending = Object.assign({}, owner.pending, { [dr.modelData.address]: false })
                dr.modelData.connect()
            }
        }
    }
}
