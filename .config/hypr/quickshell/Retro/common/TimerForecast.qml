pragma Singleton

import QtQuick
import Quickshell
import "../../shared"

Singleton {
    readonly property alias timer: countdown
    readonly property alias weather: forecast
    CountdownShared {
        id: countdown
        onFinished: Quickshell.execDetached(["notify-send", "-e", "-a", "Focus timer", "-i", "alarm-symbolic", "Time is up", "Your " + words(total) + " session has finished."])
    }
    ForecastShared { id: forecast; Component.onCompleted: refresh(false) }
}
