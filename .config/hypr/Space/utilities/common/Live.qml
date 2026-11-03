pragma Singleton

import QtQuick
import Quickshell

// one focus timer and one forecast for every monitor's bar, same shared code modern's island uses
Singleton {
    readonly property alias timer: countdown
    readonly property alias weather: forecast
    Countdown {
        id: countdown
        onFinished: Quickshell.execDetached(["notify-send", "-a", "Focus timer", "-i", "alarm-symbolic", "Time is up", "Your " + words(total) + " session has finished."])
    }
    Forecast { id: forecast; Component.onCompleted: refresh(false) }
}
