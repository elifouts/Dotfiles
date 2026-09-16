pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: theme
    property color background: "#1d2021"
    property color surface: "#282828"
    property color surfaceAlt: "#3c3836"
    property color foreground: "#ebdbb2"
    property color muted: "#928374"
    property color accent: "#fabd2f"
    property color accentAlt: "#b8bb26"
    property color orange: "#fe8019"
    property color red: "#fb4934"
    property color blue: "#83a598"
    property color purple: "#d3869b"
    property color green: "#8ec07c"
    property color border: "#504945"

    Process {
        id: palette
        command: ["sh", "-c", "cat \"$HOME/.cache/wal/colors.json\" 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const colors = JSON.parse(this.text).colors;
                    theme.background = colors.color0;
                    theme.surface = colors.color0;
                    theme.surfaceAlt = colors.color8;
                    theme.foreground = colors.color7;
                    theme.muted = colors.color8;
                    theme.accent = colors.color11;
                    theme.accentAlt = colors.color10;
                    theme.orange = colors.color9;
                    theme.red = colors.color1;
                    theme.blue = colors.color4;
                    theme.purple = colors.color5;
                    theme.green = colors.color2;
                    theme.border = colors.color8;
                } catch (error) { }
                palette.running = false;
            }
        }
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: { palette.running = false; palette.running = true }
    }
}
