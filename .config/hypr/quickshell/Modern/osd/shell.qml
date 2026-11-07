import QtQuick
import Quickshell
import Quickshell.Io
import "../../shared"
import "../common"

ShellRoot {
    OsdShared {}
    IpcHandler {
        target: "osd"
        function act(action: string): void { OsdStateShared.act(action) }
        function brightness(value: real): void { OsdStateShared.brightness(value) }
    }
}
