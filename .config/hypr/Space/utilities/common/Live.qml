pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property alias timer: countdown
    readonly property alias weather: forecast
    Countdown {
        id: countdown
        onFinished: Quickshell.execDetached(["notify-send", "-a", "Focus timer", "-i", "alarm-symbolic", "Time is up", "Your " + words(total) + " session has finished."])
    }
    Forecast { id: forecast; Component.onCompleted: refresh(false) }
}
