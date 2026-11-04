#!/usr/bin/env python3
import curses
import sys


def ui(screen, rows):
    curses.curs_set(0)
    curses.use_default_colors()
    for n, fg in ((1, curses.COLOR_CYAN), (2, curses.COLOR_RED), (3, curses.COLOR_YELLOW), (4, curses.COLOR_GREEN)):
        curses.init_pair(n, fg, -1)
    rows = rows + [("", None), ("submit", "submit")]
    picks = [i for i, (_, kind) in enumerate(rows) if kind in ("pkg", "keep")]
    marked, at, top = set(), 0, 0

    while True:
        h, w = screen.getmaxyx()
        view = max(1, h - 4)
        cur = picks[at] if at < len(picks) else len(rows) - 1
        top = min(max(top, cur - view + 1), cur)
        screen.erase()

        def put(y, x, s, attr=0):
            try:
                screen.addnstr(y, x, s, max(1, w - x - 1), attr)
            except curses.error:
                pass

        put(0, 2, "UNINSTALL  ·  space select   a all   j/k move   q quit", curses.color_pair(1) | curses.A_BOLD)
        put(1, 2, "! = you probably still need it. some of these you might've had before the dotfiles", curses.A_DIM)
        for y, i in enumerate(range(top, min(top + view, len(rows))), start=3):
            name, kind = rows[i]
            hot = curses.A_REVERSE if i == cur else 0
            if kind == "group":
                put(y, 2, name.upper(), curses.color_pair(3) | curses.A_BOLD)
            elif kind == "submit":
                put(y, 2, f"[ submit · remove {len(marked)} ]", curses.color_pair(4) | curses.A_BOLD | hot)
            elif kind:
                put(y, 4, f"[{'x' if i in marked else ' '}] {name}", hot)
                if kind == "keep":
                    put(y, 10 + len(name), "!", curses.color_pair(2) | curses.A_BOLD)
        screen.refresh()

        key = screen.getch()
        if key in (ord("q"), 27):
            return None
        if key in (curses.KEY_UP, ord("k")):
            at = max(0, at - 1)
        elif key in (curses.KEY_DOWN, ord("j")):
            at = min(len(picks), at + 1)
        elif key == curses.KEY_NPAGE:
            at = min(len(picks), at + view)
        elif key == curses.KEY_PPAGE:
            at = max(0, at - view)
        elif key == ord("a"):
            marked = set() if len(marked) == len(picks) else set(picks)
        elif key in (ord(" "), 10, 13):
            if at == len(picks):
                return [rows[i][0] for i in sorted(marked)]
            if key == ord(" "):
                marked ^= {picks[at]}


def main():
    rows = []
    for arg in sys.argv[2:]:
        if arg.startswith("@"):
            rows.append((arg[1:], "group"))
        else:
            rows.append((arg.rstrip("!"), "keep" if arg.endswith("!") else "pkg"))
    chosen = curses.wrapper(ui, rows)
    if chosen is None:
        return 1
    with open(sys.argv[1], "w") as f:
        f.write("\n".join(chosen))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
