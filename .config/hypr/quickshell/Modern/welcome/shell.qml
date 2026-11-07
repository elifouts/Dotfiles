import QtQuick
import Quickshell
import "../../shared"
import "../common"

TourShared {
    id: tour

    readonly property string sh: HyprShared.util + "/session/shells.sh"

    steps: [
        { title: "Keybinds", keys: ["SUPER", "launcher / Keybinds", "SUPER Q", "terminal", "SUPER B", "close", "SUPER 1-9", "workspaces", "SUPER TAB", "overview"] },
        { title: "Settings", hint: "ALT S", where: "settings", pages: [
            ["profile", "Tweaks save as overrides or profiles."], ["colors", "Schemes, or from your wallpaper."],
            ["windows", "Gaps, borders, tiling."], ["effects", "Blur, shadows"], ["animations", "Speed and curves."],
            ["input", "Mouse, keyboard, cursor."], ["system", "Startup and display."]] },
        { title: "Waybar", hint: "ALT A", text: "Default bar. I made a quickshell one too.", where: "bar" },
        { title: "Profiles", hint: "SUPER P", text: "My saved looks. Save yours in settings.", where: "profiles", flip: true },
        { title: "Launcher", hint: "SUPER", text: "Apps, commands, keybinds.", where: "launcher" },
        { title: "Thanks", text: "Thanks for using my dotfiles.\n— Eli" }
    ]

    spots: ({
        settings: (W, H, w, h) => Qt.point(W / 3 + 32, (H - h) / 2),
        bar: (W, H, w, h) => Qt.point((W - w) / 2, 64),
        profiles: (W, H, w, h) => Qt.point(W - 250 - 32 - w, (H - h) / 2),
        launcher: (W, H, w, h) => Qt.point((W + Math.round((4 * 70 + 3 * 26 + 36) * HyprShared.scaleFor(tour.screen)) + 24) / 2 + 32, H - h - 40)
    })

    onPanel: (name, call) => Quickshell.execDetached(["sh", "-c", (name === "settings" && call === "close" ? sh + " settings unflip; " : "") + sh + " " + name + " " + call])
    onPeek: page => Quickshell.execDetached([sh, "settings", "peek", page])

    Timer {
        interval: 1300
        repeat: true
        running: tour.active && !!tour.cur.flip && tour.fade === 1
        onTriggered: Quickshell.execDetached([tour.sh, "profiles", "flip"])
    }
}
