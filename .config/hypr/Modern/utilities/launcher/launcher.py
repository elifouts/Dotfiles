#!/usr/bin/env python3
import json
import os
import re
import shutil
import sys
import tempfile


def app_dirs():
    home = os.environ.get("XDG_DATA_HOME") or os.path.expanduser("~/.local/share")
    rest = os.environ.get("XDG_DATA_DIRS") or "/usr/local/share:/usr/share"
    return [os.path.join(d, "applications") for d in [home] + rest.split(":") if d]


def desktop_section(path):
    out = {}
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            inside = False
            for line in f:
                line = line.strip()
                if line.startswith("["):
                    if inside:
                        break
                    inside = line == "[Desktop Entry]"
                elif inside and "=" in line and not line.startswith("#"):
                    k, v = line.split("=", 1)
                    out.setdefault(k.strip(), v.strip())
    except OSError:
        pass
    return out


def split_list(v):
    return [x for x in v.split(";") if x]


def tryexec_ok(v):
    if not v:
        return True
    if os.path.isabs(v):
        return os.access(v, os.X_OK)
    return shutil.which(v) is not None


def hidden(entry, desktops):
    if entry.get("Hidden", "").lower() == "true" or entry.get("NoDisplay", "").lower() == "true":
        return True
    only = split_list(entry.get("OnlyShowIn", ""))
    if only and not any(d in only for d in desktops):
        return True
    if any(d in split_list(entry.get("NotShowIn", "")) for d in desktops):
        return True
    return not tryexec_ok(entry.get("TryExec", ""))


def apps():
    desktops = split_list(os.environ.get("XDG_CURRENT_DESKTOP", "").replace(":", ";"))
    seen, hide, paths = set(), [], {}
    for root in app_dirs():
        if not os.path.isdir(root):
            continue
        for dirpath, _, files in os.walk(root):
            for name in files:
                if not name.endswith(".desktop"):
                    continue
                path = os.path.join(dirpath, name)
                did = os.path.relpath(path, root)[: -len(".desktop")].replace("/", "-")
                if did in seen:
                    continue
                seen.add(did)
                paths[did] = path
                if hidden(desktop_section(path), desktops):
                    hide.append(did)
    json.dump({"hide": hide, "paths": paths}, sys.stdout)


def commands():
    home = os.path.expanduser("~")
    try:
        with open(os.path.join(home, ".bashrc"), encoding="utf-8", errors="replace") as f:
            rc = f.read()
    except OSError:
        rc = ""

    out = {}
    for m in re.finditer(r"^\s*alias\s+([^=\s]+)=(['\"])(.*?)\2\s*$", rc, re.M):
        out[m.group(1)] = {"n": m.group(1), "k": "alias", "d": m.group(3)}
    for m in re.finditer(r"^\s*(?:function\s+)?([A-Za-z_][\w.-]*)\s*\(\)\s*\{", rc, re.M):
        out.setdefault(m.group(1), {"n": m.group(1), "k": "function", "d": ".bashrc"})

    dirs = []
    for m in re.finditer(r'^\s*export\s+PATH="([^"]*)"', rc, re.M):
        dirs += m.group(1).replace("$HOME", home).replace("~", home).split(":")
    dirs += (os.environ.get("PATH") or "").split(":")
    seen = set()
    for d in dirs:
        if not d or d.startswith("$") or d in seen or not os.path.isdir(d):
            continue
        seen.add(d)
        try:
            names = os.listdir(d)
        except OSError:
            continue
        for name in names:
            if name in out:
                continue
            path = os.path.join(d, name)
            if os.access(path, os.X_OK) and not os.path.isdir(path):
                out[name] = {"n": name, "k": "bin", "d": d}
    json.dump(sorted(out.values(), key=lambda e: e["n"].lower()), sys.stdout)


def init(caches):
    for cache in caches:
        os.makedirs(os.path.dirname(cache) or ".", exist_ok=True)
        open(cache, "a").close()


def bump(cache, key):
    counts = {}
    try:
        with open(cache, encoding="utf-8") as f:
            for line in f:
                n, _, k = line.rstrip("\n").partition(" ")
                if k and n.isdigit():
                    counts[k] = counts.get(k, 0) + int(n)
    except OSError:
        pass
    counts[key] = counts.get(key, 0) + 1
    os.makedirs(os.path.dirname(cache) or ".", exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(cache) or ".")
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        for k, n in sorted(counts.items(), key=lambda kv: -kv[1]):
            f.write(f"{n} {k}\n")
    os.replace(tmp, cache)


if __name__ == "__main__":
    args = sys.argv[1:]
    if args[:1] == ["apps"]:
        apps()
    elif args[:1] == ["commands"]:
        commands()
    elif args[:1] == ["init"]:
        init(args[1:])
    elif args[:1] == ["bump"] and len(args) == 3:
        bump(args[1], args[2])
    else:
        sys.exit("usage: launcher.py apps | commands | init <cache>... | bump <cache> <key>")
