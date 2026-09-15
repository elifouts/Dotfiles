#!/usr/bin/env python3
import atexit
import curses
import re
import shlex
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
MANIFEST = ROOT / "InstallScripts" / "fullinstall-packages.sh"


def run(*args):
    return subprocess.run(args, text=True, stdout=subprocess.PIPE,
                          stderr=subprocess.DEVNULL, check=False).stdout


def manifest():
    text = MANIFEST.read_text()
    names = set()
    for match in re.finditer(r"(?:CORE_PACKAGES|OPTIONAL_PACKAGES)=\((.*?)\)", text, re.S):
        names.update(shlex.split(match.group(1)))
    return names


def packages(full):
    names = [line.split()[0] for line in run("pacman", "-Qe").splitlines() if line.split()]
    sizes = {}
    block = []
    for line in run("pacman", "-Qi").splitlines() + [""]:
        if line:
            block.append(line)
            continue
        name = next((item.split(":", 1)[1].strip() for item in block if item.startswith("Name")), None)
        installed_size = next((item.split(":", 1)[1].strip() for item in block if item.startswith("Installed Size")), "N/A")
        if name:
            sizes[name] = installed_size
        block = []

    result = {name: ("dotfiles" if name in full else "external", sizes.get(name, "N/A"), True) for name in names}
    for name in full - set(names):
        result[name] = ("dotfiles", "N/A", False)
    return [(name, *data) for name, data in sorted(result.items())]


def plain(items):
    print(f"{'':3} {'PACKAGE':42} {'SOURCE':10} {'SIZE':16} STATUS")
    for name, source, installed_size, installed in items:
        print(f"{'✓' if installed else '✗'} {name:42} {source:10} {installed_size:16} {'installed' if installed else 'missing'}")


def fit(value, width):
    return value if len(value) <= width else value[:max(1, width - 3)] + "..."


def ask(screen, text):
    height, width = screen.getmaxyx()
    screen.addnstr(height - 1, 2, text + " [y/N]", max(1, width - 4), curses.color_pair(4))
    screen.refresh()
    return screen.getch() in (ord("y"), ord("Y"))


def action(screen, verb, names):
    if not names or not ask(screen, f"{verb.title()} {len(names)} package(s)?"):
        return
    curses.endwin()
    command = ["yay", "-Rns" if verb == "uninstall" else "-S", *names]
    subprocess.run(command, check=False)
    input("\nPress Enter to return to the package list...")


def ui(screen, full, items):
    curses.curs_set(0)
    screen.keypad(True)
    curses.mousemask(curses.ALL_MOUSE_EVENTS | curses.REPORT_MOUSE_POSITION)
    curses.mouseinterval(0)
    print("\033[?1003h", end="", flush=True)
    atexit.register(lambda: print("\033[?1003l", end="", flush=True))
    curses.start_color()
    curses.use_default_colors()
    for number, foreground in ((1, curses.COLOR_GREEN), (2, curses.COLOR_RED),
                               (3, curses.COLOR_CYAN), (4, curses.COLOR_YELLOW),
                               (5, curses.COLOR_MAGENTA)):
        curses.init_pair(number, foreground, -1)

    column = 0
    row = 0
    view_start = 0
    preserve_scroll = False
    marked = set()

    while items:
        left = [item for item in items if item[1] == "dotfiles"]
        right = [item for item in items if item[1] == "external"]
        current = left if column == 0 else right
        row = min(row, len(current) - 1)
        height, width = screen.getmaxyx()
        screen.erase()
        gutter = 4
        left_x = 2
        right_x = width // 2 + gutter // 2
        package_width = max(12, (width - 42) // 2)
        size_width = max(4, max([len(item[2]) for item in items] + [4]))
        visible_rows = max(1, height - 9)
        max_start = max(0, max(len(left), len(right)) - visible_rows)
        view_start = min(view_start, max_start)
        if not preserve_scroll:
            if row < view_start:
                view_start = row
            elif row >= view_start + visible_rows - 1:
                view_start = min(row - visible_rows + 2, max_start)
        preserve_scroll = False
        start = view_start

        def text(y, x, value, attr=0):
            if y < height and x < width:
                try:
                    screen.addnstr(y, x, value, max(1, width - x - 1), attr)
                except curses.error:
                    pass

        text(0, 2, f"╭─ PACKAGE MANAGER ─────────────────────── {len(items)} packages", curses.color_pair(3) | curses.A_BOLD)
        text(1, 2, "│  Space select   d uninstall   r reinstall   arrows/j/k move   q quit", curses.A_DIM)
        text(2, 2, "╰" + "─" * max(1, width - 4), curses.color_pair(3))
        text(3, left_x, "DOTFILES", curses.color_pair(5) | curses.A_BOLD)
        text(3, right_x, "EXTERNAL", curses.color_pair(4) | curses.A_BOLD)
        text(4, left_x, f"    {'PACKAGE':<{package_width}} {'SIZE':>{size_width}}", curses.A_DIM)
        text(4, right_x, f"    {'PACKAGE':<{package_width}} {'SIZE':>{size_width}}", curses.A_DIM)

        for index in range(start, min(start + height - 7, max(len(left), len(right)))):
            y = 5 + index - start
            for side, group, x in ((0, left, left_x), (1, right, right_x)):
                if index >= len(group):
                    continue
                name, _, installed_size, installed = group[index]
                attr = curses.A_REVERSE if side == column and index == row else 0
                marker = "✓" if installed else "✗"
                marker_attr = curses.color_pair(1 if installed else 2) | attr
                prefix = "[x]" if name in marked else "[ ]"
                text(y, x, f"{prefix} ", attr)
                text(y, x + 4, marker, marker_attr)
                text(y, x + 7, f"{fit(name, package_width):<{package_width}} {installed_size:>{size_width}}", attr)

        text(height - 3, 2, f"Selected: {current[row][0]}", curses.A_DIM)
        uninstall_label = "[ UNINSTALL SELECTED ]"
        text(height - 1, 2, uninstall_label, curses.color_pair(2) | curses.A_BOLD)
        screen.refresh()
        key = screen.getch()
        if key == curses.KEY_MOUSE:
            _, mouse_x, mouse_y, _, mouse_state = curses.getmouse()
            if mouse_state & curses.BUTTON4_PRESSED:
                view_start = max(0, view_start - 3)
                preserve_scroll = True
                continue
            if mouse_state & curses.BUTTON5_PRESSED:
                view_start = min(max_start, view_start + 3)
                preserve_scroll = True
                continue
            if 5 <= mouse_y < height - 3:
                hovered_column = 1 if mouse_x >= right_x else 0
                hovered_group = right if hovered_column else left
                if hovered_group:
                    column = hovered_column
                    row = max(0, min(start + mouse_y - 5, len(hovered_group) - 1))
            if not mouse_state & (curses.BUTTON1_PRESSED | curses.BUTTON1_CLICKED |
                                  curses.BUTTON1_DOUBLE_CLICKED):
                continue
            if mouse_state & (curses.BUTTON1_PRESSED | curses.BUTTON1_CLICKED | curses.BUTTON1_DOUBLE_CLICKED):
                if mouse_y == height - 1 and 2 <= mouse_x < 2 + len(uninstall_label):
                    targets = list(marked) or [current[row][0]]
                    action(screen, "uninstall", targets)
                    marked.clear()
                    items = packages(full)
                    continue
                if 5 <= mouse_y < height - 3:
                    clicked_column = 1 if mouse_x >= right_x else 0
                    clicked_group = right if clicked_column else left
                    clicked_row = start + mouse_y - 5
                    if clicked_row < len(clicked_group):
                        column = clicked_column
                        row = clicked_row
            continue
        if key in (ord("q"), ord("Q")):
            return
        if key in (curses.KEY_UP, ord("k")):
            row = max(0, row - 1)
        elif key in (curses.KEY_DOWN, ord("j")):
            row = min(len(current) - 1, row + 1)
        elif key in (curses.KEY_LEFT, ord("h")) and left:
            column, row = 0, min(row, len(left) - 1)
        elif key in (curses.KEY_RIGHT, ord("l")) and right:
            column, row = 1, min(row, len(right) - 1)
        elif key == ord(" "):
            name = current[row][0]
            if current[row][3]:
                marked.symmetric_difference_update((name,))
        elif key in (10, 13, ord("d"), ord("D")):
            targets = list(marked) or [current[row][0]]
            action(screen, "uninstall", targets)
            marked.clear()
            items = packages(full)
        elif key in (ord("r"), ord("R")):
            name = current[row][0]
            if name in full:
                action(screen, "reinstall", [name])
                items = packages(full)


def main():
    if not (Path("/usr/bin/pacman").exists() and Path("/usr/bin/yay").exists()):
        print("This tool needs both pacman and yay.", file=sys.stderr)
        return 1
    full = manifest()
    items = packages(full)
    if "--list" in sys.argv[1:]:
        plain(items)
        return 0
    curses.wrapper(ui, full, items)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
