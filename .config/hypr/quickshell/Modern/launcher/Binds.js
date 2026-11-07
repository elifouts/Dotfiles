.pragma library


const CATEGORIES = [
    { id: "apps", label: "Apps", icon: "" },
    { id: "windows", label: "Windows", icon: "" },
    { id: "workspaces", label: "Workspaces", icon: "" },
    { id: "scratch", label: "Scratchpads", icon: "" },
    { id: "media", label: "Media", icon: "" },
    { id: "shots", label: "Screenshots", icon: "" },
    { id: "system", label: "System", icon: "" }
]

const ARROWS = { left: "←", right: "→", up: "↑", down: "↓" }

const KEYS = {
    "mouse:272": "LMB", "mouse:273": "RMB", "Print": "PrtSc", "ESCAPE": "Esc", "Escape": "Esc",
    "TAB": "Tab", "SPACE": "Space", "Caps_Lock": "Caps", "RETURN": "Enter", "Return": "Enter",
    "XF86AudioMute": "Mute", "XF86AudioMicMute": "Mic Mute",
    "XF86AudioRaiseVolume": "Vol +", "XF86AudioLowerVolume": "Vol −",
    "XF86MonBrightnessUp": "Bright +", "XF86MonBrightnessDown": "Bright −",
    "XF86AudioPlay": "Play", "XF86AudioNext": "Next", "XF86AudioPrev": "Prev",
    "SUPER": "Super", "SHIFT": "Shift", "CTRL": "Ctrl", "CONTROL": "Ctrl", "ALT": "Alt"
}

const OSD = {
    "vol-up": "Volume up", "vol-down": "Volume down", "vol-mute": "Mute audio", "mic-mute": "Mute microphone",
    "bright-up": "Brightness up", "bright-down": "Brightness down", "caps": "Caps Lock indicator",
    "play": "Play / pause", "next": "Next track", "prev": "Previous track"
}

const SCRIPTS = {
    "home": "Home screen", "wallpaper": "Wallpaper picker", "settings": "Settings panel", "music": "Music player",
    "refresh": "Reload Waybar", "launcher": "App launcher", "lock": "Lock screen", "profiles": "Profile switcher", "overview": "Workspace overview", "widgets": "Edit desktop widgets"
}

const NAMED = { terminal: "Terminal", fileManager: "File manager", menu: "App menu", browser: "Browser" }

function cap(s) {
    return s.charAt(0).toUpperCase() + s.slice(1)
}

function evalExpr(expr, locals, loop) {
    return expr.split("..").map(p => {
        p = p.trim()
        const s = p.match(/^"(.*)"$/)
        if (s) return s[1]
        if (locals[p] !== undefined) return locals[p]
        return loop ? "1-0" : p
    }).join("")
}

function table(expr, loop) {
    const out = {}
    const re = /(\w+)\s*=\s*("([^"]*)"|[\w.:]+)/g
    let m
    while ((m = re.exec(expr)) !== null)
        out[m[1]] = m[3] !== undefined ? m[3] : (loop && /^[a-z]$/.test(m[2]) ? "1-0" : m[2])
    return out
}

function chips(combo) {
    const parts = combo.split("+").map(s => s.trim()).filter(s => s !== "")
    if (parts.length === 2 && parts[1].replace(/_[LR]$/, "") === parts[0]) return [KEYS[parts[0]] || cap(parts[0].toLowerCase())]
    return parts.map(p => {
        if (KEYS[p]) return KEYS[p]
        if (ARROWS[p]) return ARROWS[p]
        return p.length === 1 ? p.toUpperCase() : p
    })
}

function describeCmd(cmd, expr) {
    let m
    if ((m = cmd.match(/osd\.sh\s+(\S+)/))) return { cat: "media", desc: OSD[m[1]] || m[1] }
    if (/^hyprshot\b/.test(cmd)) {
        const modes = []
        const re = /-m\s+(\w+)/g
        while ((m = re.exec(cmd)) !== null) modes.push(m[1])
        const desc = modes.includes("region") ? "Screenshot region"
            : modes.includes("output") ? "Screenshot monitor"
            : modes.includes("window") ? "Screenshot window" : "Screenshot"
        return { cat: "shots", desc: desc }
    }
    if ((m = cmd.match(/pypr\s+toggle\s+(\S+)/))) return { cat: "scratch", desc: cap(m[1]) + " scratchpad" }
    if ((m = cmd.match(/shells\.sh\s+([\w-]+)/) || cmd.match(/([\w-]+)\.sh\b/)) && SCRIPTS[m[1]])
        return { cat: m[1] === "launcher" ? "apps" : "system", desc: SCRIPTS[m[1]] }
    if (/^(pidof hyprlock \|\| )?hyprlock\b/.test(cmd)) return { cat: "system", desc: "Lock screen" }
    const prog = cmd.split(/\s+/)[0].split("/").pop()
    if (NAMED[expr.trim()]) return { cat: "apps", desc: NAMED[expr.trim()] + "  ·  " + prog }
    return { cat: "apps", desc: "Run " + prog }
}

function describe(dsp, args, locals, loop) {
    const t = table(args, loop)
    switch (dsp) {
    case "exec_cmd": return describeCmd(evalExpr(args, locals, loop), args)
    case "window.close": return { cat: "windows", desc: "Close window" }
    case "window.float": return { cat: "windows", desc: "Toggle floating" }
    case "window.pseudo": return { cat: "windows", desc: "Toggle pseudotile" }
    case "window.fullscreen": return { cat: "windows", desc: "Fullscreen" }
    case "layout": {
        const l = evalExpr(args, locals, loop)
        return { cat: "windows", desc: l === "togglesplit" ? "Toggle split direction" : "Layout " + l }
    }
    case "window.drag": return { cat: "windows", desc: "Drag window" }
    case "window.resize": return { cat: "windows", desc: "Resize window" }
    case "window.move":
        if (t.direction) return { cat: "windows", desc: "Move window", dir: t.direction }
        if (String(t.workspace).startsWith("special")) return { cat: "workspaces", desc: "Send window to special" }
        return { cat: "workspaces", desc: "Move window to workspace" }
    case "focus":
        if (t.direction) return { cat: "windows", desc: "Focus window", dir: t.direction }
        return { cat: "workspaces", desc: "Go to workspace" }
    case "workspace.toggle_special": return { cat: "workspaces", desc: "Toggle special workspace" }
    case "exit": return { cat: "system", desc: "Exit Hyprland" }
    }
    return { cat: "system", desc: cap(dsp.replace(/[._]/g, " ")) }
}

function parse(text) {
    const lines = (text || "").split("\n")
    const locals = {}
    for (const l of lines) {
        const m = l.match(/^\s*local\s+(\w+)\s*=\s*"([^"]*)"/)
        if (m) locals[m[1]] = m[2]
    }

    const binds = []
    const merged = {}
    let loop = false
    for (const raw of lines) {
        const trimmed = raw.trim()
        if (/^for\b/.test(trimmed)) loop = true
        else if (trimmed === "end") loop = false

        const g = raw.match(/^\s*hl\.gesture\((.*)\)\s*$/)
        if (g) {
            const t = table(g[1], false)
            binds.push({ cat: "workspaces", keys: [(t.fingers || "3") + "-finger swipe"], desc: t.action === "workspace" ? "Switch workspace" : cap(t.action || "Gesture") })
            continue
        }

        const m = raw.match(/^\s*hl\.bind\((.+?),\s*hl\.dsp\.([\w.]+)\((.*)\)\s*(,\s*\{[^}]*\})?\s*\)\s*$/)
        if (!m) continue
        const opts = m[4] ? table(m[4], false) : {}
        const keys = chips(evalExpr(m[1], locals, loop))
        const d = describe(m[2], m[3], locals, loop)
        if (opts.desc || opts.description) d.desc = opts.desc || opts.description

        if (d.dir && ARROWS[d.dir]) {
            const prefix = keys.slice(0, -1)
            const id = d.cat + "|" + d.desc + "|" + prefix.join("+")
            if (merged[id]) {
                const k = merged[id].keys
                k[k.length - 1] += ARROWS[d.dir]
                continue
            }
            const b = { cat: d.cat, keys: prefix.concat([ARROWS[d.dir]]), desc: d.desc }
            merged[id] = b
            binds.push(b)
            continue
        }
        binds.push({ cat: d.cat, keys: keys, desc: d.desc })
    }

    return CATEGORIES.map(c => ({
        id: c.id, label: c.label, icon: c.icon,
        binds: binds.filter(b => b.cat === c.id)
    })).filter(c => c.binds.length > 0)
}
