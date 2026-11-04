#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path

HOME = Path.home()
STORES = [HOME / ".config/mozilla/firefox", HOME / ".mozilla/firefox", HOME / ".librewolf"]
SUFFIX = re.compile(r"\s+[—–-]\s+(Mozilla Firefox|Firefox|LibreWolf)\b.*$")

def unlz4(src):
    out = bytearray()
    i = 0

    def length(n):
        nonlocal i
        if n == 15:
            while True:
                b = src[i]
                i += 1
                n += b
                if b != 255:
                    break
        return n

    while i < len(src):
        token = src[i]
        i += 1
        n = length(token >> 4)
        out += src[i:i + n]
        i += n
        if i >= len(src):
            break
        offset = src[i] | src[i + 1] << 8
        i += 2
        n = length(token & 15) + 4
        start = len(out) - offset
        if offset >= n:
            out += out[start:start + n]
        else:
            for k in range(n):
                out.append(out[start + k])
    return bytes(out)


def session():
    files = [f for d in STORES for f in d.glob("*/sessionstore-backups/recovery.jsonlz4")]
    if not files:
        return []
    data = max(files, key=lambda f: f.stat().st_mtime).read_bytes()
    if not data.startswith(b"mozLz40\0"):
        return []
    return json.loads(unlz4(data[12:])).get("windows", [])


def nth(items, i):
    items = items or [{}]
    return items[max(0, min(len(items), i) - 1)]


def current(tab):
    return nth(tab.get("entries"), tab.get("index", 1))


def urls(window):
    found = (current(tab).get("url", "") for tab in window.get("tabs", []))
    return [u for u in found if re.match(r"(https?|file)://", u)]


def title(window):
    e = current(nth(window.get("tabs"), window.get("selected", 1)))
    return e.get("title") or e.get("url", "")


def main():
    titles = [SUFFIX.sub("", t) if t else None for t in sys.argv[1:]]
    try:
        windows = session()
    except (OSError, ValueError, IndexError):
        windows = []
    found = [None] * len(titles)
    left = list(windows)
    for i, t in enumerate(titles):
        w = next((w for w in left if t is not None and title(w) == t), None)
        if w:
            found[i] = w
            left.remove(w)
    missing = [i for i, t in enumerate(titles) if t is not None and found[i] is None]
    if len(missing) == 1 and len(left) == 1:
        found[missing[0]] = left[0]
    for w in found:
        print("\037".join(urls(w)) if w else "")


if __name__ == "__main__":
    main()
