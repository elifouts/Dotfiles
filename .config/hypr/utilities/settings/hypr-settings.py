#!/usr/bin/env python3

import json
import os
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

HYPR = Path(__file__).resolve().parents[2]
HOME = Path.home()
LUA_FILE = HYPR / "state/settings.lua"
STATE = HYPR / "state"
ACTIVE_SAVED_FILE = STATE / "saved.json"
THEME_FILE = STATE / "color-theme"
PROFILE_FILE = STATE / "profile"
BAR_FILE = STATE / "bar"
QUICKSHELL_FILE = STATE / "bar-style"
SCHEMES = HOME / ".config/wal/colorschemes"
LOOK_KEYS = ("wallpaper.", "colors.", "bar.", "waybar.", "quickshell.")
INTERNAL_SCHEMES = {"pywal16"}
UI_FILE = HOME / ".local/state/hypr-settings/ui.json"
USAGE = "usage: hypr-settings.py state KEY... | set KEY=JSON... | reset | sync | cursor | colors | appearance | ui KEY=JSON... | saved save|apply|delete|preview|wipe [ID]"
CURSOR_DIRS = [HOME / ".icons", HOME / ".local/share/icons", Path("/usr/share/icons")]


def run(*cmd):
    return subprocess.run(cmd, capture_output=True, text=True).stdout


def load(path, default):
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError):
        return default


def write_atomic(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(text)
    tmp.replace(path)


def lua(value, depth=0):
    pad = "    " * (depth + 1)
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return repr(value)
    if isinstance(value, str):
        return json.dumps(value)
    if isinstance(value, list):
        return "{ " + ", ".join(lua(v, depth) for v in value) + " }"
    items = "".join(f"{pad}[{json.dumps(k)}] = {lua(v, depth + 1)},\n" for k, v in sorted(value.items()))
    return "{\n" + items + "    " * depth + "}"


def active_profile():
    return PROFILE_FILE.read_text().strip() if PROFILE_FILE.exists() else "default"


def tweaks_dir():
    return HYPR / active_profile().partition("/")[0] / "tweaks"


def tweaks_file(variant=None):
    return tweaks_dir() / f"{variant or active_profile().partition('/')[2]}.json"


def saved_dir():
    return tweaks_dir() / "saved" / active_profile().partition("/")[2]


def default_look_file():
    return tweaks_dir() / "default-look.json"


def migrate():
    old = HYPR / "tweaks"
    if not old.is_dir():
        return
    for path in old.glob("saved/*/*.json"):
        style, _, variant = path.parent.name.partition("-")
        dest = HYPR / style / "tweaks/saved" / variant / path.name
        dest.parent.mkdir(parents=True, exist_ok=True)
        path.replace(dest)
    for path in old.glob("*-*.json"):
        if path.name == "default-look.json":
            continue
        style, _, variant = path.stem.partition("-")
        (HYPR / style / "tweaks").mkdir(parents=True, exist_ok=True)
        path.replace(HYPR / style / "tweaks" / f"{variant}.json")
    looks = {}
    for profile, look in load(old / "default-look.json", {}).items():
        style, _, variant = profile.partition("/")
        looks.setdefault(style, {})[variant] = look
    for style, look in looks.items():
        write_atomic(HYPR / style / "tweaks/default-look.json", json.dumps(look, indent=2, sort_keys=True) + "\n")
    (old / "default-look.json").unlink(missing_ok=True)
    for d in sorted(old.glob("**/"), reverse=True):
        d.rmdir() if not any(d.iterdir()) else None


def own_variant():
    return "variant:" + active_profile().partition("/")[2]


def entry_file(entry):
    kind, _, name = entry.partition(":")
    if kind == "variant":
        return tweaks_file(name)
    if kind == "saved":
        return saved_dir() / f"{name}.json"
    return None


def live_entry():
    mark = load(ACTIVE_SAVED_FILE, {}).get(active_profile(), "")
    if mark and ":" not in mark and mark != "default":
        mark = "saved:" + mark
    if mark == "default" or (mark and entry_file(mark) and entry_file(mark).is_file()):
        return mark
    return own_variant() if tweaks_file().is_file() else "default"


def set_live_entry(entry):
    marks = load(ACTIVE_SAVED_FILE, {})
    marks[active_profile()] = entry
    write_atomic(ACTIVE_SAVED_FILE, json.dumps(marks, indent=2, sort_keys=True) + "\n")


def entry_settings(entry):
    if entry == "default":
        return load(default_look_file(), {}).get(active_profile().partition("/")[2], {})
    path = entry_file(entry)
    return load(path, {}) if path else {}


def live_settings():
    return entry_settings(live_entry())


def settings_wallpaper(s):
    return real_wallpaper(os.path.expandvars(dig(s, "wallpaper.path") or "")) or real_wallpaper(current_wallpaper())


def write_lua(settings):
    write_atomic(LUA_FILE, "return " + lua(settings) + "\n"
                 if settings else "return {}\n")


def portable(settings):
    path = dig(settings, "wallpaper.path")
    if isinstance(path, str):
        home = str(HOME)
        settings["wallpaper"]["path"] = "$HOME" + path[len(home):] if path.startswith(home + "/") else re.sub(r"^/home/[^/]+/", "$HOME/", path)
    return settings


def save(settings):
    entry = live_entry()
    if entry == "default":
        entry = own_variant()
    write_atomic(entry_file(entry), json.dumps(portable(settings), indent=2, sort_keys=True) + "\n")
    set_live_entry(entry)
    write_lua(settings)


def prune(tree):
    for key in [k for k, v in tree.items() if isinstance(v, dict)]:
        prune(tree[key])
        if not tree[key]:
            del tree[key]


def reapply(reload=False):
    run("hyprctl", "eval", 'package.loaded.settings=nil package.loaded.overrides=nil require("overrides")')
    if reload:
        run("hyprctl", "reload", "config-only")


def startup_defaults():
    code = ('local d=require("machine").defaults '
            'return string.format("%s %d %s %d", tostring(d.boot.enabled), d.boot.black_ms, d.cursor.theme, d.cursor.size)')
    parts = run("hyprctl", "repl", code).split()
    if len(parts) == 4:
        return {"boot": {"enabled": parts[0] == "true", "black_ms": int(parts[1])},
                "cursor": {"theme": parts[2], "size": int(parts[3])}}
    return {"boot": {"enabled": True, "black_ms": 100}, "cursor": {"theme": "default", "size": 16}}


def option(path):
    raw = run("hyprctl", "getoption", "-j", path.replace(".", ":"))
    try:
        data = json.loads(raw)
    except ValueError:
        return None
    for kind in ("bool", "int", "float"):
        if kind in data:
            return data[kind]
    for kind in ("str", "custom", "css"):
        if kind in data:
            text = data[kind]
            if kind == "css":
                nums = text.split()
                return int(nums[0]) if nums and len(set(nums)) == 1 and nums[0].lstrip("-").isdigit() else text
            return "" if text == "[[EMPTY]]" else text
    return None


def dig(tree, dotted):
    for part in dotted.split("."):
        if not isinstance(tree, dict) or part not in tree:
            return None
        tree = tree[part]
    return tree


def profiles():
    found = {}
    for style in sorted(HYPR.iterdir()):
        if (style / "base/style.lua").is_file():
            found[style.name] = sorted(m.stem for m in (HYPR / "machine").glob("*.lua"))
    active = PROFILE_FILE.read_text().strip() if PROFILE_FILE.exists() else ""
    style, _, variant = active.partition("/")
    return found, {"style": style, "variant": variant}


def themes():
    out = []
    for path in sorted(SCHEMES.glob("*/*.json")):
        if path.stem in INTERNAL_SCHEMES:
            continue
        data = load(path, {})
        colors, special = data.get("colors", {}), data.get("special", {})
        palette = [colors.get(f"color{i}") for i in range(16)]
        if not all(palette):
            continue
        palette += [special.get("background", palette[0]), special.get("foreground", palette[15]),
                    special.get("cursor", special.get("foreground", palette[15]))]
        out.append({"id": f"{path.parent.name}/{path.stem}",
                    "name": data.get("name") or path.stem.replace("-", " ").replace("_", " ").title(),
                    "palette": palette, "custom": bool(data.get("custom"))})
    return out


def style_dir():
    return HYPR / (PROFILE_FILE.read_text().strip().partition("/")[0] if PROFILE_FILE.exists() else "")


def bar_styles(folder, marker):
    out = []
    for d in sorted((style_dir() / folder).glob("*/")):
        if not (d / marker).is_file():
            continue
        image = next((d / f for f in ("preview.svg", "preview.png") if (d / f).is_file()), None)
        out.append({"id": d.name, "name": d.name.replace("-", " ").title(), "image": str(image) if image else ""})
    return out


def waybar():
    styles, live, base = bar_styles("waybar", "style.css"), HOME / ".config/waybar", style_dir() / "waybar"
    same = lambda s: (live / "style.css").is_file() and (base / s["id"] / "style.css").read_bytes() == (live / "style.css").read_bytes()
    return {"styles": styles, "active": next((s["id"] for s in styles if same(s)), "")}


def quickshell():
    styles, live = bar_styles("quickshellbar", "config.json"), load_text(QUICKSHELL_FILE) or DEFAULT_QUICKSHELL
    return {"styles": styles, "active": live if any(s["id"] == live for s in styles) else ""}


def cursors():
    names = {d.name for base in CURSOR_DIRS if base.is_dir() for d in base.iterdir() if (d / "cursors").is_dir()}
    return sorted(names, key=str.lower)


def mice():
    devices = json.loads(run("hyprctl", "devices", "-j") or "{}")
    return [m["name"] for m in devices.get("mice", []) if "touchpad" not in m["name"]]


def has_touchpad():
    devices = json.loads(run("hyprctl", "devices", "-j") or "{}")
    return any("touchpad" in m["name"] for m in devices.get("mice", []))


def monitor_count():
    return len(json.loads(run("hyprctl", "monitors", "-j") or "[]"))


def wallpaper_palette(path, index=None):
    for entry in load(HOME / ".cache/wallpaper-picker/index.json", []) if index is None else index:
        if entry.get("path") == path:
            return entry.get("colors", [])
    colors = load(HOME / ".cache/wal/colors.json", {}).get("colors", {})
    return [colors.get(f"color{i}") for i in range(16) if colors.get(f"color{i}")]


FALLBACKS = {
    "animation.preset": "theme",
    "utilities.animations": False,
    "utilities.opacity": 1.0,
    "utilities.clock24": False,
    "animation.speed": 1.0,
    "animation.curve": [0.15, 0.85, 0.25, 1.0],
    "animation.window": "popin 90%",
    "animation.workspace": "slide",
    "border.gradient": False,
    "border.palette": "accent",
    "border.angle": 45,
}


def cmd_state(keys):
    settings = live_settings()
    defaults = None
    values = {}
    live = [k for k in keys if k.startswith("config.")]
    with ThreadPoolExecutor(8) as pool:
        for key, value in zip(live, pool.map(lambda k: option(k[len("config."):]), live)):
            values[key] = value
    for key in keys:
        if key.startswith("config."):
            continue
        value = dig(settings, key)
        if value is None:
            if key.startswith(("boot.", "cursor.")):
                defaults = defaults or startup_defaults()
                value = dig(defaults, key)
            else:
                value = FALLBACKS.get(key)
        values[key] = value
    styles, active = profiles()
    colors = current_theme()
    wallpaper = current_wallpaper()
    print(json.dumps({
        "values": values,
        "styles": styles,
        "active": active,
        "themes": themes(),
        "colorTheme": colors or "pywal",
        "wallpaper": wallpaper,
        "pywalPalette": wallpaper_palette(wallpaper),
        "caps": {"touchpad": has_touchpad(), "multimonitor": monitor_count() > 1},
        "cursors": cursors(),
        "waybar": waybar(),
        "bar": current_bar(),
        "quickshell": quickshell(),
        "saved": saved_state(),
    }))


RELOAD_ON_CHANGE = {"border.gradient"}


def put(settings, pairs):
    reload = False
    for pair in pairs:
        key, _, raw = pair.partition("=")
        value = json.loads(raw)
        if isinstance(value, (list, dict)) and key.startswith("config."):
            continue
        node = settings
        *parents, leaf = key.split(".")
        for part in parents:
            node = node.setdefault(part, {})
        if value is None:
            node.pop(leaf, None)
            reload = True
        else:
            node[leaf] = value
        if key in RELOAD_ON_CHANGE and not value:
            reload = True
        if key == "config.input.sensitivity":
            settings["mice"] = mice()
    prune(settings)
    return reload


def cmd_set(pairs):
    default = live_entry() == "default"
    if default and all(p.partition("=")[0].startswith(LOOK_KEYS) for p in pairs):
        looks, variant = load(default_look_file(), {}), active_profile().partition("/")[2]
        put(looks.setdefault(variant, {}), pairs)
        portable(looks[variant])
        write_atomic(default_look_file(), json.dumps(looks, indent=2, sort_keys=True) + "\n")
        return
    settings = load(tweaks_file(), {}) if default else live_settings()
    reload = put(settings, pairs)
    save(settings)
    reapply(reload)
    if any(p.startswith("cursor.") for p in pairs):
        cmd_cursor()
    if any(p.startswith("utilities.clock24=") for p in pairs):
        cmd_waybar_clock()
    if "space.world=null" in pairs:
        sync_world(live_settings())
        detached(str(HYPR / "utilities/colors/color-apply.sh"), dig(settings, "colors.theme") or DEFAULT_THEME)


def cmd_waybar_clock():
    h24 = dig(live_settings(), "utilities.clock24")
    if h24 is None:
        h24 = FALLBACKS["utilities.clock24"]
    path = HOME / ".config/waybar/config"
    text = path.read_text() if (style_dir() / "waybar").is_dir() and path.is_file() else ""
    clock = re.sub(r"%I:%M:%S %p|%H:%M:%S", "%H:%M:%S" if h24 else "%I:%M:%S %p", text)
    if clock != text:
        path.write_text(clock)
        run("pkill", "-USR2", "-x", "waybar")


def cmd_reset():
    go_live("default")


def cmd_sync():
    settings = live_settings()
    write_lua(settings)
    kind = bar_kind(settings)
    if kind in ("waybar", "quickshell") and load_text(BAR_FILE) != kind:
        write_atomic(BAR_FILE, kind + "\n")
    look = dig(settings, "quickshell.style")
    if look and look != load_text(QUICKSHELL_FILE) and any(s["id"] == look for s in quickshell()["styles"]):
        write_atomic(QUICKSHELL_FILE, look + "\n")


def cmd_cursor():
    cursor = live_settings().get("cursor", {})
    fallback = startup_defaults()["cursor"]
    run("hyprctl", "setcursor", cursor.get("theme", fallback["theme"]), str(cursor.get("size", fallback["size"])))


def saved_name(raw):
    name = " ".join("".join(c for c in raw if c.isalnum() or c in " -_").split())[:40]
    if not name:
        sys.exit("saved profile needs a name")
    return name


def saved_state():
    style = active_profile().partition("/")[0]
    entries = [{"id": "default", "name": "Default", "kind": "default", "exists": True}]
    for variant in profiles()[0].get(style, []):
        entries.append({"id": "variant:" + variant, "name": variant.capitalize(), "kind": "variant",
                        "exists": tweaks_file(variant).is_file()})
    for name in sorted((p.stem for p in saved_dir().glob("*.json")), key=str.lower):
        entries.append({"id": "saved:" + name, "name": name, "kind": "saved", "exists": True})
    return {"entries": entries, "active": live_entry()}


def saved_preview():
    state = saved_state()
    index = load(HOME / ".cache/wallpaper-picker/index.json", [])
    thumbs = {w.get("path"): w.get("thumb") for w in index}
    out = []
    for e in (e for e in state["entries"] if e["exists"]):
        s = entry_settings(e["id"])
        theme = dig(s, "colors.theme") or DEFAULT_THEME
        wallpaper = settings_wallpaper(s)
        thumb = thumbs.get(wallpaper) or wallpaper
        if theme == "pywal":
            colors = wallpaper_palette(wallpaper, index)
        else:
            scheme = (theme == "dark/space" and dig(world_of(s) or {}, "palette.colors")) or load(SCHEMES / f"{theme}.json", {}).get("colors", {})
            colors = [scheme.get(f"color{i}") for i in range(16)]
        kind = bar_kind(s)
        look = dig(s, "quickshell.style") or DEFAULT_QUICKSHELL if kind == "quickshell" else dig(s, "waybar.style") or DEFAULT_WAYBAR
        out.append({**e, "colors": [c for c in colors if c], "thumb": thumb, "bar": f"{kind} / {look}",
                    "rounding": 10 if (r := dig(s, "config.decoration.rounding")) is None else r,
                    "opacity": dig(s, "config.decoration.active_opacity") or 0.78,
                    "border": dig(s, "config.general.border_size") or 0,
                    "blur": dig(s, "config.decoration.blur.enabled") is not False,
                    "curve": dig(s, "animation.curve") or [0.15, 0.85, 0.25, 1],
                    "ms": 400 / max(0.1, dig(s, "animation.speed") or 1) if dig(s, "animation") else 300,
                    "style": dig(s, "animation.window") or "popin 5%"})
    return {"entries": out, "active": state["active"]}


DEFAULT_THEME = "pywal"
DEFAULT_WAYBAR = "default"
DEFAULT_BAR = "waybar"
DEFAULT_QUICKSHELL = "default"


WALLPAPER_FILE = HOME / ".cache/wallpaper-picker/current"


def current_wallpaper():
    return WALLPAPER_FILE.read_text().strip() if WALLPAPER_FILE.exists() else ""


def bar_kind(settings):
    kind = dig(settings, "bar.kind") or DEFAULT_BAR
    return kind if kind != "waybar" or (style_dir() / "waybar").is_dir() else "quickshell"


def current_bar():
    return "quickshell" if load_text(BAR_FILE) == "quickshell" else DEFAULT_BAR


def current_theme():
    return (THEME_FILE.read_text().strip() if THEME_FILE.exists() else "") or DEFAULT_THEME


def detached(*cmd, env=None):
    spawn = subprocess.run if os.environ.get("HYPR_SETTINGS_WAIT") else subprocess.Popen
    spawn(cmd, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
          start_new_session=True, env={**os.environ, **(env or {})})


def real_wallpaper(path):
    if path and Path(path).name == "pywallpaper.jpg":
        path = next((p for p in (current_wallpaper(), load_text(HOME / ".cache/wal/wal"))
                     if p and Path(p).name != "pywallpaper.jpg"), path)
    return path if path and Path(path).is_file() else ""


def load_text(path):
    try:
        return path.read_text().strip()
    except OSError:
        return ""


def world_of(settings):
    return dig(settings, "space.world") or dig(entry_settings("default"), "space.world")


def sync_world(settings):
    world = world_of(settings)
    if not world:
        return
    write_atomic(SCHEMES / "dark/space.json", json.dumps(world["palette"]))
    path = HOME / ".config/space/world.json"
    write_atomic(path, json.dumps({**load(path, {}), "hue": world["hue"], "curTheme": world["theme"], "random": world["random"], "restored": True}))


def cmd_colors():
    settings = live_settings()
    sync_world(settings)
    theme = dig(settings, "colors.theme") or DEFAULT_THEME
    subprocess.run([str(HYPR / "utilities/colors/color-apply.sh"), theme, settings_wallpaper(settings)], env={**os.environ, "COLOR_NO_RELOAD": "1"},
                   stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def cmd_appearance():
    settings = live_settings()
    if not os.environ.get("COLORS_DONE"):
        sync_world(settings)
    theme = dig(settings, "colors.theme") or DEFAULT_THEME
    wallpaper = settings_wallpaper(settings)
    if wallpaper:
        write_atomic(THEME_FILE, theme + "\n")
        detached(str(HYPR / "utilities/wallpaper/wallpaper-apply.sh"), wallpaper, env={"HYPR_SETTINGS_NO_RECORD": "1", "WALLPAPER_TRANSITION": os.environ.get("WALLPAPER_TRANSITION", "fade")})
    elif theme != current_theme():
        detached(str(HYPR / "utilities/colors/color-apply.sh"), theme)
    if not any((style_dir() / d).is_dir() for d in ("waybar", "quickshellbar")):
        return
    kind = bar_kind(settings)
    if kind != current_bar():
        subprocess.run([str(HYPR / "utilities/bars/bar.sh"), "apply", kind], env={**os.environ, "HYPR_SETTINGS_NO_RECORD": "1"},
                       stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    look = dig(settings, "quickshell.style") or DEFAULT_QUICKSHELL
    qs = quickshell()
    if look != qs["active"] and any(s["id"] == look for s in qs["styles"]):
        detached(str(HYPR / "utilities/bars/bar.sh"), "style", look, env={"HYPR_SETTINGS_NO_RECORD": "1"})
    bar = waybar()
    style = DEFAULT_WAYBAR if kind == "quickshell" else dig(settings, "waybar.style") or DEFAULT_WAYBAR
    if style != bar["active"] and any(s["id"] == style for s in bar["styles"]):
        detached(str(HYPR / "utilities/bars/waybar-style.sh"), "apply", style, env={"HYPR_SETTINGS_NO_RECORD": "1"})


def go_live(entry):
    set_live_entry(entry)
    write_lua(live_settings())
    reapply(reload=True)
    cmd_cursor()
    cmd_appearance()


def cmd_saved(args):
    action, raw = (args + ["", ""])[:2]
    if action == "save":
        name = saved_name(raw)
        snapshot = live_settings()
        snapshot.setdefault("colors", {})["theme"] = current_theme()
        if current_wallpaper():
            snapshot.setdefault("wallpaper", {})["path"] = current_wallpaper()
        if waybar()["active"]:
            snapshot.setdefault("waybar", {})["style"] = waybar()["active"]
        snapshot.setdefault("bar", {})["kind"] = current_bar()
        look = quickshell()["active"]
        if look:
            snapshot.setdefault("quickshell", {})["style"] = look
        write_atomic(saved_dir() / f"{name}.json", json.dumps(portable(snapshot), indent=2, sort_keys=True) + "\n")
        set_live_entry("saved:" + name)
    elif action == "apply":
        path = entry_file(raw)
        if raw != "default" and not (path and (path.is_file() or raw == own_variant())):
            sys.exit(f"nothing to apply for {raw}")
        go_live(raw)
    elif action == "delete":
        path = entry_file(raw)
        if path is None:
            sys.exit("Default can't be deleted")
        was_live = live_entry() == raw
        path.unlink(missing_ok=True)
        if was_live:
            go_live("default")
    elif action == "preview":
        print(json.dumps(saved_preview()))
    elif action == "wipe":
        for path in list((tweaks_dir() / "saved").glob("*/*.json")) + list(tweaks_dir().glob("*.json")):
            if path.name != "default-look.json":
                path.unlink()
        for d in (tweaks_dir() / "saved").glob("*/"):
            d.rmdir()
        ACTIVE_SAVED_FILE.unlink(missing_ok=True)
        go_live("default")
    else:
        sys.exit(USAGE)


def cmd_ui(pairs):
    ui = load(UI_FILE, {})
    for pair in pairs:
        key, _, raw = pair.partition("=")
        ui[key] = json.loads(raw)
    write_atomic(UI_FILE, json.dumps(ui))


def main():
    migrate()
    command, args = (sys.argv[1], sys.argv[2:]) if len(sys.argv) > 1 else ("", [])
    handlers = {"state": cmd_state, "set": cmd_set, "ui": cmd_ui, "saved": cmd_saved}
    bare = {"reset": cmd_reset, "sync": cmd_sync, "cursor": cmd_cursor, "colors": cmd_colors, "appearance": cmd_appearance, "waybar-clock": cmd_waybar_clock}
    if command in bare:
        bare[command]()
    elif command in handlers:
        handlers[command](args)
    else:
        sys.exit(USAGE)


if __name__ == "__main__":
    main()
