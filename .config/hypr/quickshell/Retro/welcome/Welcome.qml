import QtQuick
import "../../shared"
import "../common"

TourShared {
    id: tour

    steps: [
        { title: "Keybinds", keys: ["SUPER", "programs", "SUPER Q", "terminal", "SUPER B", "close", "SUPER TAB", "tasks", "ALT TAB", "status"] },
        { title: "Setup", hint: "ALT S", where: "settings", beat: 800, pages: [
            ["core", "Style, bar, font."], ["colors", "Pick a tube or use the wallpaper."], ["screen", "The CRT filter. Presets up top."],
            ["windows", "Gaps, borders, tiling."], ["effects", "Blur, glow, shadows."], ["animations", "Speed and curves."],
            ["input", "Mouse, keyboard, cursor."], ["system", "Display, wake, clock."], ["profiles", "Save your setup."]] },
        { title: "Bar", hint: "ALT A", text: "Hover a readout to open it.", where: "bar" },
        { title: "Programs", hint: "SUPER", text: "Type a name or a number. Tab for commands.", where: "launcher" },
        { title: "Screens", hint: "ALT W", text: "Wallpapers get drawn for the tube.", where: "wallpaper" },
        { title: "Tasks", hint: "SUPER TAB", text: "Every window. Enter to go, x to close.", where: "overview" },
        { title: "Thanks", text: "Thanks for using my dotfiles.\n— Eli" }
    ]

    readonly property var top: (W, H, w, h) => Qt.point((W - w) / 2, 50)
    spots: ({ settings: top, launcher: top, wallpaper: top, overview: top, bar: (W, H, w, h) => Qt.point((W - w) / 2, 70) })

    Binding { target: Ui; property: "touring"; value: tour.active }
}
