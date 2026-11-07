import QtQuick
import "../../shared"

SequentialAnimation {
    id: rise
    property Item target
    property int index
    property int replay
    function play() { if (target) restart() }
    Component.onCompleted: play()
    onTargetChanged: play()
    onReplayChanged: play()

    PropertyAction { target: rise.target; property: "opacity"; value: 0 }
    PropertyAction { target: rise.target; property: "scale"; value: 0.97 }
    PauseAnimation { duration: Theme.ms(Math.min(rise.index, 8) * 30) }
    ParallelAnimation {
        SettleShared { target: rise.target; property: "opacity"; to: 1; duration: Theme.move }
        SettleShared { target: rise.target; property: "scale"; to: 1; duration: Theme.move }
    }
}
