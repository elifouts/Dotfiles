import QtQuick
import Quickshell.Hyprland
import "../../shared"
import "../common"

TourShared {
    id: tour

    steps: [
        { title: "Keybinds", keys: ["SUPER", "launcher", "SUPER Q", "terminal", "SUPER B", "close", "SUPER 1-9", "workspaces", "SUPER TAB", "galaxy map"] },
        { title: "Settings", hint: "ALT S", where: "settings", beat: 800, pages: [
            ["core", "Style, machine."], ["colors", "Themes and accents."], ["fonts", "Any font you have."],
            ["windows", "Gaps, borders, tiling."], ["effects", "Blur, glow, shadows."], ["animations", "Speed and curves."],
            ["input", "Mouse, keyboard, cursor."], ["system", "Display, wake, clock."], ["profiles", "Save your tweaks."]] },
        { title: "Bar", hint: "ALT A", text: "Click a readout to open its panel.", where: "bar" },
        { title: "Workspaces", hint: "SUPER 1-9", text: "Each workspace is a spot on the land.", where: "workspaces" },
        { title: "Worlds", hint: "ALT W", text: "This is what changes your colors.", where: "world" },
        { title: "Launcher", hint: "SUPER", text: "Apps and commands. Tab switches.", where: "launcher" },
        { title: "Overview", hint: "SUPER TAB", text: "Workspaces are stars, windows are planets.\nWASD flies, click a star to land.", where: "overview", ms: 20000 },
        { title: "Thanks", text: "Thanks for using my dotfiles.\n— Eli" }
    ]

    spots: ({
        settings: (W, H, w, h) => Qt.point((W - w) / 2, H - 480 - h),
        bar: (W, H, w, h) => Qt.point((W - w) / 2, 64),
        launcher: (W, H, w, h) => Qt.point((W - w) / 2, 366),
        overview: (W, H, w, h) => Qt.point((W - w) / 2, H - h - 70)
    })

    Binding { target: Ui; property: "touring"; value: tour.active }

    property bool landing: false
    onLandingChanged: if (!landing && cur.where === "overview" && step === shown) go(1)

    property int home: 1
    onPanel: (name, call) => {
        if (name === "world" && call === "open") World.hop()
        if (name !== "workspaces") return
        if (call === "close") {
            back.stop()
            return HyprShared.focusWs(home)
        }
        home = Hyprland.monitorFor(screen)?.activeWorkspace?.id ?? 1
        const taken = Hyprland.workspaces.values.map(w => w.id)
        let free = home + 1
        while (taken.includes(free)) free++
        HyprShared.focusWs(home)
        HyprShared.focusWs(free)
        back.restart()
    }
    Timer { id: back; interval: 2500; onTriggered: HyprShared.focusWs(tour.home) }
}
