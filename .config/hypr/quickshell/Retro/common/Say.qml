import QtQuick

Type {
    caps: false
    property int replay
    onReplayChanged: run()
}
