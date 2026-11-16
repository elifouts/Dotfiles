import QtQuick

Timer {
    property bool on: true
    interval: 530
    repeat: true
    onRunningChanged: on = true
    onTriggered: on = !on
}
