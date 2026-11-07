import QtQuick
import Quickshell.Hyprland
import "../../shared"
import "../common"

Item {
    id: stars

    readonly property int focused: Hyprland.focusedWorkspace?.id ?? 1
    readonly property var onScreen: Hyprland.monitors.values.map(m => m.activeWorkspace?.id ?? -1)
    readonly property var existing: HyprShared.workspaces
    readonly property var ids: HyprShared.workspaceIds
    function count(id) { return existing.find(w => w.id === id)?.toplevels.values.length ?? 0 }
    function go(id) { if (id !== focused) Hyprland.dispatch("hl.dsp.focus({ workspace = " + id + " })") }
    function cx(id) { return Math.max(0, ids.indexOf(id)) * Theme.starGap + Theme.starGap / 2 }

    width: ids.length * Theme.starGap
    height: parent.height

    Repeater {
        model: stars.ids
        Item {
            id: star
            required property int modelData
            required property int index
            readonly property bool lit: modelData === stars.focused
            readonly property bool shown: stars.onScreen.includes(modelData)
            readonly property int windows: stars.count(modelData)
            x: index * Theme.starGap
            width: Theme.starGap
            height: stars.height

            Orb {
                visible: star.lit || star.shown
                anchors.centerIn: parent
                width: 18; height: 18
                tint: Theme.accent
                core: star.lit ? 0.36 : 0.24
                glow: star.lit ? 1 : 0.5
                opacity: star.lit ? 1 : 0.75
                Behavior on core { SettleShared { duration: Theme.quick } }
            }
            Rectangle {
                visible: !star.lit && !star.shown
                anchors.centerIn: parent
                width: star.windows ? 6 : 4
                height: width
                radius: width / 2
                color: Theme.alpha(Theme.fg, (star.windows ? 0.6 : 0.22) + (area.containsMouse ? 0.3 : 0))
            }
            Item {
                id: orbit
                readonly property int moons: star.lit || star.shown ? 0 : Math.min(4, star.windows - 1)
                visible: moons > 0
                anchors.centerIn: parent
                width: 14; height: 14
                Timer {
                    interval: 33
                    repeat: true
                    running: orbit.visible && Theme.quick > 0
                    onTriggered: orbit.rotation = (Date.now() % 6000) * 0.06
                }
                Repeater {
                    model: Math.max(0, orbit.moons)
                    Rectangle {
                        required property int index
                        readonly property real a: index * 2 * Math.PI / orbit.moons
                        x: 6 + 6 * Math.cos(a)
                        y: 6 + 6 * Math.sin(a)
                        width: 2; height: 2; radius: 1
                        color: Theme.alpha(Theme.fg, 0.55)
                    }
                }
            }
            MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; onClicked: stars.go(star.modelData) }
        }
    }
    WheelHandler {
        onWheel: e => {
            const i = stars.ids.indexOf(stars.focused)
            stars.go(stars.ids[Math.max(0, Math.min(stars.ids.length - 1, i + (e.angleDelta.y > 0 ? -1 : 1)))])
        }
    }

    property int last: focused
    property real head: cx(focused)
    property real tail: cx(focused)
    onFocusedChanged: {
        const from = cx(last), to = cx(focused)
        last = focused
        if (from === to || !Theme.quick) return
        headAnim.from = tailAnim.from = from
        headAnim.to = tailAnim.to = to
        shoot.restart()
    }
    ParallelAnimation {
        id: shoot
        SettleShared { id: headAnim; target: stars; property: "head"; duration: Theme.ms(360) }
        NumberAnimation { id: tailAnim; target: stars; property: "tail"; duration: Theme.ms(360); easing.type: Easing.InQuad }
    }
    Rectangle {
        visible: shoot.running
        x: Math.min(stars.head, stars.tail)
        width: Math.abs(stars.head - stars.tail)
        height: 1.5
        anchors.verticalCenter: parent.verticalCenter
        rotation: stars.head < stars.tail ? 180 : 0
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 1; color: Theme.accent }
        }
    }
}
