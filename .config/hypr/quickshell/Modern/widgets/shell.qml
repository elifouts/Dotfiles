import QtQuick
import Quickshell
import Quickshell.Io
import "../../shared"

Scope {
    IpcHandler {
        target: "widgets"
        function toggle(): void { WidgetStateShared.toggle() }
    }
    WidgetHostShared { style: "modern" }
}
