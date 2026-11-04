import QtQuick
import Quickshell
import Quickshell.Io
import "../common"

ShellRoot {
    Osd {}
    IpcHandler {
        target: "osd"
        function act(action: string): void { OsdState.act(action) }
        function brightness(value: real): void { OsdState.brightness(value) }
    }
}
