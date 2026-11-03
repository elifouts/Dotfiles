import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../common"
import "../land"
import "../ui"

// star map over every monitor. workspaces are named stars, each with its home planet plus one planet per window,
// scratchpads are moons of the home planet. mouse looks, wasd / arrows / hjkl fly, the crosshair picks
Scope {
    id: map

    signal done()

    // camera, with momentum so flying glides instead of snapping
    property real px: 0
    property real py: 0
    property real pz: 0
    property real yaw: 0
    property real pitch: 0
    property real aimYaw: 0
    property real aimPitch: 0
    property var vel: [0, 0, 0]
    property var held: ({})
    // everything projects through this one object, set once a frame, so each star re-evaluates once instead of per write.
    // f is the lens (it widens while you're moving fast) and v is how fast, for the star streaks
    property var cam: ({ x: 0, y: 0, z: 0, cy: 1, sy: 0, cp: 1, sp: 0, f: focal, v: 0 })
    function setView(x, y, z, yw, pt, v) {
        px = x; py = y; pz = z; yaw = yw; pitch = pt
        v = Math.min(1, v ?? 0)
        cam = { x: x, y: y, z: z, cy: Math.cos(yw), sy: Math.sin(yw), cp: Math.cos(pt), sp: Math.sin(pt), f: focal / (1 + 0.28 * v), v: v }
    }
    // the selected system opening up: rings and planets grow out of their star. 1 = fully open
    property real bloom: 1
    function openSystem() { bloomAnim.restart() }
    SequentialAnimation {
        id: bloomAnim
        PropertyAction { target: map; property: "bloom"; value: 0 }
        PauseAnimation { duration: 160 }
        NumberAnimation { target: map; property: "bloom"; to: 1; duration: 900; easing.type: Easing.OutQuint }
    }
    // the land on top: ascent 0 = standing on it, 1 = up in orbit. ground is its opacity
    property real ascent: 0
    property real ground: 1
    // the wallpaper covering your windows. fades in as you leave and out as you arrive, so they dissolve and return
    property real veil: 0
    property var sel: null
    property var landing: null
    // the bodies the takeoff or landing is drawing full screen. the map's copies sit hidden under it and show the
    // moment it's fully up, both draw the same so swapping is invisible (crossfading them used to dim it)
    property var transitKeys: []
    // [planet, its star] for the handoff's lighting, and the moon the wallpaper's moon turns into
    property var transitLight: null
    property var transitMoon: null

    // projection centred on the screen it opened on, under the crosshair
    readonly property var home: Ui.target ?? Quickshell.screens[0]
    readonly property real cx: home.x + home.width / 2
    readonly property real cy: home.y + home.height / 2
    readonly property real focal: Math.max(home.width, home.height) * 0.6
    // how far you hover in front of a focused star
    readonly property real hover: focal / 35
    // planets: world radius, how big the home planet is when you're parked in front of it, and how far that is.
    // the wallpaper's orbit view ends at exactly that size, so landing and takeoff hand over without a jump
    readonly property real planetR: 0.5
    readonly property real planetPx: 70
    readonly property real planetDist: planetR * focal / planetPx
    readonly property real endR: planetPx / home.height
    // ring radii: the home planet's round the star, each window planet further out, moons round the home planet
    readonly property real homeR: 8
    readonly property real ringGap: 3
    readonly property real worldR: 0.34
    readonly property real moonR: 0.14

    readonly property int current: Hyprland.focusedWorkspace?.id ?? 1
    readonly property var used: Hyprland.workspaces.values.filter(w => w.id > 0).sort((a, b) => a.id - b.id)
        .map(w => ({ kind: "ws", id: w.id, ws: w, pos: World.starOf(w.id) }))
    readonly property var scratch: Hyprland.workspaces.values.filter(w => w.name.startsWith("special:") && w.toplevels.values.length)

    function starSize(s) { return Math.min(30, 5 + 7 * s) }
    function fwd() { return [Math.sin(yaw) * Math.cos(pitch), Math.sin(pitch), Math.cos(yaw) * Math.cos(pitch)] }
    function mix3(a, b, t) { return [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t] }
    function sub3(a, b) { return [a[0] - b[0], a[1] - b[1], a[2] - b[2]] }
    // world vector into camera space (x right, y up, z forward), rel does it for a point
    function toCam(vx, vy, vz) {
        const c = cam
        const x1 = vx * c.cy - vz * c.sy, z1 = vx * c.sy + vz * c.cy
        return [x1, vy * c.cp - z1 * c.sp, vy * c.sp + z1 * c.cp]
    }
    function rel(p) { return toCam(p[0] - cam.x, p[1] - cam.y, p[2] - cam.z) }
    // world point -> desktop pixels, s is the perspective scale, null when it's behind you
    function project(p) {
        const c = cam, q = rel(p)
        if (q[2] < 1.5) return null
        return { x: cx + q[0] / q[2] * c.f, y: cy - q[1] / q[2] * c.f, s: c.f / q[2] / 8, z: q[2] }
    }
    // which way the star is from a planet, in the shader's space (z toward you), so every planet is lit by its own sun
    function sunDir(from, to) {
        if (!from || !to) return Qt.vector4d(-0.35, 0.6, 0.7, 0)
        const q = toCam(...sub3(to, from)), l = Math.hypot(...q) || 1
        return Qt.vector4d(q[0] / l, q[1] / l, -q[2] / l, 0)
    }
    // where the transit moon sits on screen next to its planet, for the wallpaper's moon to land on (see Terrain.moonEnd)
    readonly property var moonEnd: {
        const m = transitMoon, b = transitLight
        const q = m && b ? project(shown(m)) : null, h = q ? project(b[0]) : null
        if (!q || !h) return Qt.vector4d(0, 0, 0, 0)
        const H = home.height
        return Qt.vector4d((q.x - cx) / H, 0.5 - (q.y - cy) / H, m.r * cam.f / q.z / H, q.z < h.z ? 2 : 1)
    }
    // a 3d line on screen, cut where it crosses behind you so the constellation never just vanishes
    function segment(a, b) {
        const n = 1.5
        let qa = rel(a), qb = rel(b)
        if (qa[2] < n && qb[2] < n) return null
        if (qa[2] < n) qa = mix3(qa, qb, (n - qa[2]) / (qb[2] - qa[2]))
        else if (qb[2] < n) qb = mix3(qb, qa, (n - qb[2]) / (qa[2] - qb[2]))
        const sc = q => Qt.point(cx + q[0] / q[2] * cam.f, cy - q[1] / q[2] * cam.f)
        return [sc(qa), sc(qb)]
    }
    // angles that look at a point, yaw the short way round so it never spins you
    function lookAt(from, to) {
        const d = sub3(to, from)
        let y = Math.atan2(d[0], d[2])
        while (y - yaw > Math.PI) y -= Math.PI * 2
        while (y - yaw < -Math.PI) y += Math.PI * 2
        return [y, Math.atan2(d[1], Math.hypot(d[0], d[2]))]
    }

    // stars near the camera, one per lucky grid cell, rebuilt only when you cross into a new cell. sparse on purpose,
    // the far sky shader does the rest of the vastness for free
    readonly property int cell: 35
    readonly property real density: 0.3
    readonly property string here: [Math.floor(cam.x / cell), Math.floor(cam.y / cell), Math.floor(cam.z / cell)].join()
    property var wild: []
    ListModel { id: wildModel }
    // new seed, pool or theme (after landing) re-rolls the undiscovered ones
    function reroll() { wildModel.clear(); rebuild() }
    Connections {
        target: World
        function onSeedChanged() { map.reroll() }
        function onPoolChanged2() { map.reroll() }
        function onCurThemeChanged() { map.reroll() }
    }
    function hash(a, b, c) { return r3(a + World.seed * 31, b, c) }
    onHereChanged: rebuild()
    function rebuild() {
        const [a0, b0, c0] = here.split(",").map(Number), out = []
        for (let i = -4; i <= 4; i++) for (let j = -2; j <= 2; j++) for (let k = -4; k <= 4; k++) {
            const a = a0 + i, b = b0 + j, c = c0 + k
            if (hash(a, b, c) > density) continue
            out.push({ kind: "wild", id: a + "," + b + "," + c, hue: World.snap(hash(c, a, b), true), temp: hash(b, a, c), size: 0.6 + hash(a, c, b) * 0.9,
                       pos: [(a + hash(b, c, a)) * cell, (b + hash(c, b, a)) * cell * 0.6, (c + hash(a, a, c)) * cell] })
        }
        const byId = {}, have = new Set()
        for (const w of out) byId[w.id] = w
        for (let i = wildModel.count - 1; i >= 0; i--) {
            const id = wildModel.get(i).sid
            if (byId[id]) have.add(id)
            else wildModel.remove(i)
        }
        for (const w of out) if (!have.has(w.id))
            wildModel.append({ sid: w.id, shue: w.hue, stemp: w.temp, ssize: w.size, wx: w.pos[0], wy: w.pos[1], wz: w.pos[2] })
        // same order as the model, so a delegate's index finds its star and its projection
        const ordered = []
        for (let i = 0; i < wildModel.count; i++) ordered.push(byId[wildModel.get(i).sid])
        wild = ordered
    }
    // every near star projected once a frame and shared, each monitor's window and the crosshair used to redo it
    readonly property var wildP: wild.map(w => project(w.pos))

    // per-system randomness from the star's position, no world seed so a system keeps its look when the world rerolls
    function r3(a, b, c) {
        let h = (a * 374761393 + b * 668265263 + c * 2147483647) | 0
        h = Math.imul(h ^ (h >>> 13), 1274126177)
        return ((h ^ (h >>> 16)) >>> 0) / 4294967295
    }
    function sysRand(s, n) { return r3(Math.round(s.pos[0]) + n * 7919, Math.round(s.pos[1]) + n * 104729, Math.round(s.pos[2])) }
    // a system's colour scheme starts from its hue. uncharted stars already have one
    function sysHue(s) {
        if (s.kind === "wild") return s.hue
        const placed = World.stars[s.id]
        return placed?.[3] !== undefined && (World.random || World.themeFor(placed[3])) ? placed[3] : World.snap(sysRand(s, 1))
    }
    // window planets take the other accents of the system's own theme, so they all differ but stay in the palette
    function worldHue(s, i) {
        const h = sysHue(s), f = World.random ? null : World.themeFor(h)
        if (!f) return (h + (i + 1) * 0.618) % 1
        return World.accentHue(f.t.c[3 + (f.i - 3 + i + 1) % 6])
    }
    function sysSeed(s, n = 5) { return 1 + Math.round(sysRand(s, n) * 996) }
    function tiltOf(s) { return 0.22 + sysRand(s, 2) * 0.3 }
    // a point on one of a system's orbits. rings and planets both come from this, so planets sit on their ring
    function orbitC(c, t, r, a) {
        const x = Math.cos(a) * r, z = Math.sin(a) * r
        return [c[0] + x, c[1] - z * Math.sin(t), c[2] + z * Math.cos(t)]
    }
    function orbit(s, r, a) { return orbitC(s.pos, tiltOf(s), r, a) }
    function isTransit(o) { return transitKeys.indexOf(o.key) >= 0 }
    // takeoff view: looking at the planet with its star off to one side, a bit over a third lit. the star stays in
    // view so the planet never looks like it's orbiting nothing
    // and it looks down on the orbits from viewEl above their plane, level with it the rings were just lines.
    // a is that direction's angle round the orbit, the moon sits a bit round from it
    readonly property real viewEl: 0.85
    function viewOf(sys, h) {
        const t = tiltOf(sys), N = [0, Math.cos(t), Math.sin(t)], d = [0, 1, 2].map(i => sys.pos[i] - h[i]), l = Math.hypot(...d) || 1
        const u = d.map(v => v / l), w = [N[1] * u[2] - N[2] * u[1], N[2] * u[0] - N[0] * u[2], N[0] * u[1] - N[1] * u[0]]
        const ep = u.map((v, i) => v * Math.cos(2.0) + w[i] * Math.sin(2.0))
        return { e: ep.map((v, i) => v * Math.cos(viewEl) + N[i] * Math.sin(viewEl)),
                 a: Math.atan2(-ep[1] * Math.sin(t) + ep[2] * Math.cos(t), ep[0]) }
    }

    // every system has its home planet, the land you'd stand on. a new star is a new world
    function homeOf(sys) {
        const a = sysRand(sys, 3) * Math.PI * 2
        return { kind: "home", key: "h" + sys.id, sys: sys, ring: homeR, r: planetR, hue: sysHue(sys), seed: sysSeed(sys), star: sys.pos, a: a, pos: orbit(sys, homeR, a) }
    }
    // every home planet has its own moon, the one in the wallpaper's sky. it sits off to the side of the takeoff view
    // so you watch the sky's moon turn into it
    readonly property real natR: 1.7
    function moonOf(h) {
        const a = viewOf(h.sys, h.pos).a + 1.2, t = tiltOf(h.sys)
        return { kind: "moon", key: "n" + h.sys.id, natural: true, sys: h.sys, ring: "n", rr: natR, r: 0.17,
                 a: a, center: h.pos, star: h.sys.pos, hue: h.hue, seed: h.seed, pos: orbitC(h.pos, t, natR, a) }
    }
    // the open system: home planet, a planet per window further out, scratchpads as moons on the home planet
    readonly property var bodies: {
        if (!sel) return []
        const h = homeOf(sel), t = tiltOf(sel), out = [h, moonOf(h)]
        if (sel.kind === "ws") {
            sel.ws.toplevels.values.forEach((w, i) => {
                const r = homeR + ringGap * (i + 1), a = sysRand(sel, 20 + i) * Math.PI * 2
                out.push({ kind: "planet", key: "p" + w.address, window: w, wsid: sel.id, ring: "p" + i, rr: r, r: worldR, center: sel.pos, star: sel.pos,
                           hue: worldHue(sel, i), seed: sysSeed(sel, 10 + i), a: a, pos: orbit(sel, r, a) })
            })
            scratch.forEach((w, i) => {
                const r = natR + 0.7 + i * 0.5, a = i * 2.4 + sysRand(sel, 4) * Math.PI * 2
                out.push({ kind: "moon", key: "s" + w.name, special: w.name.slice(8), sys: sel, ring: "m" + i, rr: r, r: moonR, center: h.pos, star: sel.pos,
                           hue: h.hue, seed: h.seed, a: a, pos: orbitC(h.pos, t, r, a) })
            })
        }
        return out
    }
    // a0 is where its body sits, so each ring draws itself out of its planet
    readonly property var rings: bodies.map(b => b.kind === "home" ? { key: homeR, c: sel.pos, r: homeR, moon: false, a0: b.a }
                                                              : { key: b.ring, c: b.center, r: b.rr, moon: b.kind === "moon", a0: b.a })
    // 0..1 how much of the rings is drawn. rides the takeoff/landing camera, otherwise the system's bloom
    property real ringDraw: 1
    // ring i drawn so far, inner rings first, each a beat after the last
    function ringFrac(i) { return Math.max(0, Math.min(1, Math.min(ringDraw, bloom) * (1 + 0.15 * rings.length) - 0.15 * i)) }
    // one orbit ring as polylines in desktop pixels, split wherever it swings behind or too close to the camera.
    // worked out once a frame here, the windows just shift by their own offset (it was rebuilt per monitor before)
    function ringPath(rg, f) {
        if (!sel || bloom < 0.02 || f <= 0) return []
        const out = []
        let seg = []
        const N = Math.max(2, Math.ceil((rg.moon ? 32 : 56) * f)), rr = rg.r * bloom, t = tiltOf(sel)
        const c = rg.moon ? shown({ star: true, pos: rg.c }) : rg.c
        for (let i = 0; i <= N; i++) {
            const q = project(orbitC(c, t, rr, (rg.a0 ?? 0) + i / N * f * Math.PI * 2))
            if (q && q.z > 4) seg.push(Qt.point(q.x, q.y))
            else { if (seg.length > 1) out.push(seg); seg = [] }
        }
        if (seg.length > 1) out.push(seg)
        return out
    }
    readonly property var ringPts: (1 - ground) > 0 ? rings.map((rg, i) => ringPath(rg, ringFrac(i))) : []
    // labels, lines, crosshair and markers fade in over the pull back instead of popping in at the handoff
    property real ui: 1

    // where a body is drawn: growing out of its star while the system opens, moons out of their planet
    function shown(o) {
        if (bloom >= 1 || !o.star || !sel) return o.pos
        const c = o.center ?? o.pos, cs = mix3(sel.pos, c, bloom)
        return o.center ? mix3(cs, [cs[0] + o.pos[0] - c[0], cs[1] + o.pos[1] - c[1], cs[2] + o.pos[2] - c[2]], bloom) : cs
    }
    function screenOf(o) { return project(shown(o)) }
    // how far to park from a body so it fills the wallpaper's orbit view
    function distFor(o) { return (o.r ?? planetR) * focal / planetPx }

    // whatever is closest to the crosshair. anything you can't see can't be aimed at
    readonly property var aimed: {
        let best = null, bestD = 40
        const near = (p, o, far) => {
            if (!p || p.z > far) return
            const d = Math.hypot(p.x - cx, p.y - cy)
            if (d < bestD) { bestD = d; best = o }
        }
        const open = bloom > 0.9
        for (const o of bodies.concat(used)) {
            const body = !!o.star
            if (body && !open) continue
            near(screenOf(o), o, body ? 400 : 160)
        }
        const wp = wildP
        for (let i = 0; i < wp.length; i++) near(wp[i], wild[i], 160)
        return best
    }

    // what the info card is about, the star it's on hides its own label so the two don't stack
    readonly property var carded: busy ? null : (aimed ?? sel)
    // real star colours: white, a few a touch blue or warm
    function colorOf(t) { return t < 0.2 ? "#d6e4ff" : t > 0.85 ? "#ffe9cf" : "#ffffff" }
    function appOf(w) { return (w?.lastIpcObject?.class || w?.title || "").split(".").pop() }
    function nameOf(w) { return [...new Set(w.toplevels.values.map(appOf).filter(x => x))].slice(0, 2).join(" · ") }
    function sysName(id) { return "system " + String(id).padStart(2, "0") }
    function currentStar() { return used.find(u => u.id === current) ?? { kind: "ws", id: current, pos: World.starOf(current) } }

    // takeoff and landing are one motion each, driven by go (0 = on the ground, 1 = out in the map). the first
    // liftA of it is the wallpaper rising into a planet, the rest is the map's camera carrying on at the exact speed
    // the planet was shrinking, so there's no stop in orbit and no second move toward the star
    property real go: 0
    // play with these: how long each takes and the curve, a cubic bezier like css (x1, y1, x2, y2).
    // this is css "ease": quick to get going, long gentle finish
    readonly property int takeoffMs: 3800
    readonly property int landMs: 3100
    readonly property var curve: [0.25, 0.1, 0.25, 1.0]
    // landing starts from your click so it gets going sooner
    readonly property var landCurve: [0.15, 0.25, 0.25, 1.0]
    readonly property real liftA: 0.5
    // how far along the launch you can grab the controls
    readonly property real takeOverAt: 0.9
    // the camera's half: pulls back from planet h along e from d0 to d1 while its aim slides from h to "to"
    property var path: null
    function pathTo(h, e, d0, d1, to) {
        d1 = Math.max(d1, d0 * 1.3)
        // matches the shader's shrink rate at the handoff (see land.frag, p slope 1/0.72 at rise 1), capped so it can't overshoot
        const mu = Math.max(0.5, Math.min(3, Math.log(3.5 / endR) * 0.35 / 0.55 * (1 - liftA) / liftA / Math.log(d1 / d0)))
        return { h: h, e: e, d0: d0, d1: d1, to: to, mu: mu }
    }
    function pose(s) {
        // starts at the handoff speed and ends straight (go's own easing does the settling, easing twice felt stuck)
        const P = path, m = P.mu * s + (2 - 2 * P.mu) * s * s + (P.mu - 1) * s * s * s, k = s * s * (2 - s)
        const D = P.d0 * Math.pow(P.d1 / P.d0, m), c = P.h.map((v, i) => v + P.e[i] * D)
        const [y, pt] = lookAt(c, mix3(P.h, P.to, k))
        const w = Math.sin(Math.PI * s)
        setView(c[0], c[1], c[2], y, pt, w * w * 0.5)
        aimYaw = y; aimPitch = pt
    }
    property bool touched: false
    onGoChanged: {
        if (!path) return
        const s = (go - liftA) / (1 - liftA)
        if (go > liftA) { ascent = 1; ground = 0; ringDraw = Math.min(1, s * 1.8); ui = Math.max(0, Math.min(1, (s - 0.15) * 2)); return pose(s) }
        ringDraw = 0
        ui = 0
        if (ascent === 1) pose(0)
        ascent = go / liftA
        ground = 1
        if (!descend.running) return
        // coming down: the workspace switch happens at the handoff
        if (!touched) { touched = true; if (!land()) { descend.stop(); done() } }
    }

    Component.onCompleted: {
        Hyprland.refreshToplevels()
        sel = currentStar()
        const ho = homeOf(sel), h = ho.pos, e = viewOf(sel, h).e
        transitKeys = [ho.key, "n" + sel.id]
        transitLight = [h, sel.pos]
        transitMoon = moonOf(ho)
        // straight back off your planet and stay on it, the star just sits behind. no turn, so it's one move
        path = pathTo(h, e, planetDist, hover * 0.6, h)
        pose(0)
        rebuild()
        center()
        takeoff.start()
    }
    function arrive() { path = null; ui = 1; ringDraw = 1 }
    // the launch spends its last stretch on a settle you can barely see, so once it's basically there (takeOverAt) any key
    // or mouse move stops it where it is and hands you control. earlier than that a twitch would freeze the pull back
    function takeOver() {
        if (!takeoff.running) return true
        if (go < takeOverAt) return false
        takeoff.stop()
        arrive()
        return true
    }
    SequentialAnimation {
        id: takeoff
        ParallelAnimation {
            NumberAnimation { target: map; property: "veil"; to: 1; duration: 600; easing.type: Easing.OutCubic }
            NumberAnimation { target: map; property: "go"; from: 0; to: 1; duration: map.takeoffMs; easing.type: Easing.BezierSpline; easing.bezierCurve: map.curve.concat([1, 1]) }
        }
        ScriptAction { script: map.arrive() }
    }

    // fly over to something and turn to face it together, eased so it doesn't make you dizzy. the lens widens mid-flight
    // and the near stars streak, that's most of the speed feeling. one animation drives it, so a frame is one view update
    property var flyFrom: [0, 0, 0, 0, 0]
    property var flyTo: [0, 0, 0, 0, 0]
    property real flyKick: 1
    property real flyT: 0
    function focus(o) {
        if (!o) return
        if (!o.star && sel?.id !== o.id) { sel = o; openSystem() }
        const s = o.pos, d = [s[0] - px, s[1] - py, s[2] - pz], len = Math.max(0.001, Math.hypot(...d))
        const back = o.kind === "home" ? distFor(o) : o.star ? hover * 0.5 : hover
        const to = [s[0] - d[0] / len * back, s[1] - d[1] / len * back, s[2] - d[2] / len * back]
        const [ty, tp] = lookAt(to, s)
        flyFrom = [px, py, pz, yaw, pitch]
        flyTo = to.concat([ty, tp])
        fly.duration = Math.max(800, Math.min(1400, 560 + len * 4))
        // short hops barely kick
        flyKick = Math.min(1, len / 140)
        aimYaw = ty; aimPitch = tp
        vel = [0, 0, 0]
        fly.restart()
    }
    onFlyTChanged: {
        if (!fly.running && flyT < 1) return
        const k = flyT, w = Math.sin(Math.PI * k), v = flyFrom.map((a, i) => a + (flyTo[i] - a) * k)
        setView(v[0], v[1], v[2], v[3], v[4], w * w * flyKick)
    }
    NumberAnimation { id: fly; target: map; property: "flyT"; from: 0; to: 1; easing.type: Easing.InOutCubic }
    // the crosshair's click: any planet, moon or the focused star lands, any other star gets flown to
    function act() {
        const o = aimed
        if (!o || busy) return
        if (o.star || (sel && o.id === sel.id)) warp(o)
        else focus(o)
    }

    // landing is the takeoff backwards from wherever you are: straight in toward the planet, it hands over to the
    // wallpaper at the same speed and you come down onto it. a moon lands you on its home planet (a scratchpad one
    // pulls the scratchpad up after)
    function warp(o) {
        if (!o || busy) return
        landing = o
        const dest = o.kind === "moon" ? homeOf(o.sys) : o.star ? o : homeOf(o)
        // landing on a system that isn't the selected one (esc from far away): bring its planet out without the bloom
        if (!o.star && sel?.id !== o.id) { bloomAnim.stop(); bloom = 1; sel = o }
        const home = dest.kind === "home"
        transitKeys = home ? [dest.key, "n" + dest.sys.id] : [dest.key]
        transitLight = [dest.pos, dest.star]
        transitMoon = home ? moonOf(dest) : null
        landHue = dest.hue
        landSeed = dest.seed
        const h = dest.pos, v = [px - h[0], py - h[1], pz - h[2]], L = Math.hypot(...v) || 1, f = fwd()
        path = pathTo(h, v.map(x => x / L), distFor(dest), L, [px + f[0] * L, py + f[1] * L, pz + f[2] * L])
        fly.stop()
        vel = [0, 0, 0]
        touched = false
        // a bit longer from far away
        descend.ms = landMs + Math.min(500, L * 5)
        descend.start()
    }
    function close() { if (!busy) warp(currentStar()) }
    SequentialAnimation {
        id: descend
        property int ms: 4200
        NumberAnimation { target: map; property: "go"; from: 1; to: 0; duration: descend.ms; easing.type: Easing.BezierSpline; easing.bezierCurve: map.landCurve.concat([1, 1]) }
        // only once it's fully down, so this landscape is pixel for pixel the real wallpaper and just your windows fade back.
        // letting go even a few percent early showed the still wallpaper under the one still settling
        NumberAnimation { target: map; property: "veil"; to: 0; duration: 320; easing.type: Easing.InOutSine }
        ScriptAction { script: map.done() }
    }
    property int landWs: current
    property real landHue: -1
    property real landSeed: World.landSeed
    function focusWs(id) { Hyprland.dispatch("hl.dsp.focus({ workspace = " + id + " })") }
    function land() {
        const l = landing.star ? (landing.kind === "planet" ? landing : landing.sys) : landing
        if (l.kind === "wild") {
            let id = 1
            while (used.some(u => u.id === id)) id++
            World.place(id, l.pos, l.hue)
            landWs = id
            landHue = l.hue
            focusWs(id)
        } else if (l.kind === "planet") {
            const a = String(l.window.address || "")
            if (!a) return false
            landWs = l.wsid
            Hyprland.dispatch("hl.dsp.focus({ window = \"address:" + (a.startsWith("0x") ? a : "0x" + a) + "\" })")
        } else {
            landWs = l.id
            if (landHue !== World.hue || landSeed !== World.landSeed) World.reroll(landHue, landSeed)
            if (l.id !== current) focusWs(l.id)
            // a moon is a scratchpad, land on its home world then pull it up (unless it's already showing)
            const sp = landing.special
            if (sp && Hyprland.focusedMonitor?.lastIpcObject?.specialWorkspace?.name !== "special:" + sp)
                Hyprland.dispatch("hl.dsp.workspace.toggle_special(\"" + sp + "\")")
            return true
        }
        World.reroll(l.hue, landSeed)
        return true
    }

    // flying: keys push, momentum carries, it eases to a stop. only ticks while something is moving
    readonly property bool busy: takeoff.running || fly.running || descend.running
    // done() sometimes never came and left invisible overlays eating the launcher
    // fully covered, so the wallpaper can stop twinkling under it
    Binding { target: Ui; property: "overview"; value: map.veil > 0.99 }
    readonly property bool drawn: busy || veil > 0 || ascent > 0.001
    onDrawnChanged: if (!drawn) done()
    readonly property bool flying: Object.keys(held).length > 0 || Math.hypot(...vel) > 0.05
        || Math.abs(aimYaw - yaw) > 0.0005 || Math.abs(aimPitch - pitch) > 0.0005
    FrameAnimation {
        running: map.flying && !map.busy
        onTriggered: {
            const dt = Math.min(0.05, frameTime), k = map.held, top = k.fast ? 260 : 80
            const f = map.fwd(), rx = Math.cos(map.yaw), rz = -Math.sin(map.yaw)
            const go = (k.f ? 1 : 0) - (k.b ? 1 : 0), side = (k.r ? 1 : 0) - (k.l ? 1 : 0)
            if (k.tl) map.aimYaw -= 1.2 * dt
            if (k.tr) map.aimYaw += 1.2 * dt
            const want = [(f[0] * go + rx * side) * top, f[1] * go * top, (f[2] * go + rz * side) * top]
            // speeds up quick, glides out slower
            const e = 1 - Math.exp(-dt * (go || side ? 4 : 2.2))
            const v = map.vel.map((c, i) => c + (want[i] - c) * e)
            map.vel = v
            const t = 1 - Math.exp(-dt * 7)
            map.setView(map.px + v[0] * dt, map.py + v[1] * dt, map.pz + v[2] * dt,
                        map.yaw + (map.aimYaw - map.yaw) * t, map.pitch + (map.aimPitch - map.pitch) * t, Math.hypot(...v) / 260)
        }
    }
    readonly property var binds: ({
        [Qt.Key_W]: "f", [Qt.Key_Up]: "f", [Qt.Key_K]: "f", [Qt.Key_S]: "b", [Qt.Key_Down]: "b", [Qt.Key_J]: "b",
        [Qt.Key_A]: "l", [Qt.Key_Left]: "l", [Qt.Key_H]: "l", [Qt.Key_D]: "r", [Qt.Key_Right]: "r", [Qt.Key_L]: "r",
        [Qt.Key_Q]: "tl", [Qt.Key_E]: "tr", [Qt.Key_Shift]: "fast"
    })
    function key(e, down) {
        if (e.isAutoRepeat || !takeOver() || descend.running) return
        if (down && e.key === Qt.Key_Escape) return close()
        if (down && (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)) return act()
        if (down && e.key === Qt.Key_Space) return focus(currentStar())
        if (down && (e.key === Qt.Key_Tab || e.key === Qt.Key_Backtab) && used.length) {
            const i = Math.max(0, used.findIndex(u => u.id === sel?.id))
            return focus(used[(i + (e.key === Qt.Key_Backtab ? used.length - 1 : 1)) % used.length])
        }
        const b = binds[e.key]
        if (!b) return
        const h = Object.assign({}, held)
        if (down) h[b] = true
        else delete h[b]
        held = h
    }

    // mouse look: the pointer is hidden and kept in the middle, only how far it moved matters
    property real lastX: cx
    property real lastY: cy
    function center() {
        lastX = cx; lastY = cy
        Hyprland.dispatch("hl.dsp.cursor.move({ x = " + Math.round(cx) + ", y = " + Math.round(cy) + " })")
    }
    // the key hint shows for a few seconds after the map opens, then gets out of the way
    property bool idle: false
    Timer { running: true; interval: 6000; onTriggered: map.idle = true }
    function look(gx, gy) {
        const dx = gx - lastX, dy = gy - lastY
        lastX = gx; lastY = gy
        // the warp back to the middle shows up as one big jump, skip it
        if (!takeOver() || busy || Math.abs(dx) > 120 || Math.abs(dy) > 120) return
        aimYaw += dx * 0.0011
        aimPitch = Math.max(-1.3, Math.min(1.3, aimPitch - dy * 0.0011))
        if (Math.hypot(gx - cx, gy - cy) > 240) center()
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: win
            required property var modelData
            readonly property bool main: modelData === map.home
            readonly property real ox: modelData.x
            readonly property real oy: modelData.y
            screen: modelData
            visible: map.drawn
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            // see-through, so your windows can dissolve into the wallpaper and back instead of cutting to black
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "space-overview"
            WlrLayershell.keyboardFocus: main ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            // hides your windows while you're away. the sky fades in over it only once the wallpaper lets go
            Rectangle { anchors.fill: parent; color: "black"; opacity: Math.max(0, Math.min(1, (map.veil - 0.5) * 2)) }

            Item {
            id: sky
            anchors.fill: parent
            visible: map.ascent > 0.01
            opacity: Math.min(1, map.ascent * 1.5)

            ShaderEffect {
                anchors.fill: parent
                readonly property real yaw: map.yaw
                readonly property real pitch: map.pitch
                readonly property real focal: map.cam.f
                readonly property real offX: win.ox - map.cx
                readonly property real offY: win.oy - map.cy
                readonly property real sizeW: width
                readonly property real sizeH: height
                readonly property color tint1: Theme.accent
                readonly property color tint2: Theme.accent2
                readonly property color base: Theme.mix(Theme.bg, "#000000", 0.7)
                fragmentShader: Qt.resolvedUrl("starmap.frag.qsb")
            }

            // the near stars: plain dots, way cheaper than a shader each. moving fast stretches them away from the middle
            Repeater {
                model: wildModel
                Rectangle {
                    required property real shue
                    required property real stemp
                    required property real ssize
                    required property int index
                    readonly property var p: map.wildP[index] ?? null
                    readonly property real far: p ? Math.min(1, p.z / 150) : 1
                    readonly property real dx: p ? p.x - map.cx : 0
                    readonly property real dy: p ? p.y - map.cy : 0
                    readonly property real d: p ? Math.max(2, Math.min(4.5, 1.2 + ssize * p.s * 0.45)) : 0
                    visible: !!p && far < 1 && p.z > 3
                    width: d + map.cam.v * Math.hypot(dx, dy) / Math.max(6, p?.z ?? 6) * 1.4
                    height: d
                    radius: d / 2
                    x: (p?.x ?? 0) - win.ox - width / 2
                    y: (p?.y ?? 0) - win.oy - height / 2
                    rotation: Math.atan2(dy, dx) * 180 / Math.PI
                    antialiasing: true
                    // tinted with the theme it'd give you, so you can tell they're different worlds
                    color: Theme.mix(map.colorOf(stemp), Qt.hsla(shue, 0.7, 0.7, 1), 0.5)
                    opacity: (1 - far * far) * Math.min(1, ((p?.z ?? 0) - 3) / 10) * (0.65 + ssize * 0.25)
                    // the same soft halo the known stars get, one shared sprite so they all draw in a single batch
                    Image {
                        anchors.centerIn: parent
                        width: 8 + parent.d * 6; height: width
                        source: "glow.png"
                        smooth: true
                        opacity: 0.95 * (1 - map.cam.v)
                    }
                }
            }

            // the open system's orbit rings in its own colours. the one you aim at lights up
            Repeater {
                model: map.rings
                Shape {
                    id: rg
                    required property var modelData
                    required property int index
                    readonly property real tone: map.sel ? map.sysHue(map.sel) : 0
                    readonly property bool lit: !!map.aimed && map.aimed.ring === modelData.key
                    // drawn in desktop pixels, shifted to this monitor
                    x: -win.ox
                    y: -win.oy
                    width: win.width + win.ox
                    height: win.height + win.oy
                    z: 3
                    opacity: (1 - map.ground) * Math.min(1, map.bloom * 2)
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeWidth: rg.lit ? 1.5 : 1
                        strokeColor: Qt.hsla(rg.tone, 0.45, 0.72, rg.lit ? 0.7 : rg.modelData.moon ? 0.26 : 0.18)
                        fillColor: "transparent"
                        PathMultiline { paths: map.ringPts[rg.index] ?? [] }
                    }
                }
            }

            // the constellation: lines between your systems in order, clipped instead of dropped when one end is behind you
            Repeater {
                model: map.used.length > 1 ? map.used.length - 1 : 0
                Rectangle {
                    required property int index
                    readonly property var g: map.segment(map.used[index].pos, map.used[index + 1].pos)
                    visible: !!g
                    x: g ? g[0].x - win.ox : 0
                    y: g ? g[0].y - win.oy : 0
                    width: g ? Math.hypot(g[1].x - g[0].x, g[1].y - g[0].y) : 0
                    height: 1
                    rotation: g ? Math.atan2(g[1].y - g[0].y, g[1].x - g[0].x) * 180 / Math.PI : 0
                    transformOrigin: Item.Left
                    antialiasing: true
                    color: Theme.alpha(Theme.accent, 0.32 * map.ui)
                }
            }

            // your systems: a small glowing star and its name
            Repeater {
                model: map.used
                Item {
                    id: u
                    required property var modelData
                    readonly property var p: map.project(modelData.pos)
                    readonly property real far: p ? Math.min(1, p.z / 170) : 1
                    readonly property bool picked: map.sel?.id === modelData.id
                    z: 5
                    Orb {
                        id: sb
                        property real boost: u.picked ? 1.7 : 1
                        Behavior on boost { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                        // your systems never fade out with distance, so you can always see where every workspace is
                        visible: !!u.p && u.p.z > 3
                        width: map.starSize(u.p?.s ?? 0) * boost
                        height: width
                        x: (u.p?.x ?? 0) - win.ox - width / 2
                        y: (u.p?.y ?? 0) - win.oy - height / 2
                        tint: Theme.mix("#ffffff", Theme.accent, 0.25)
                        core: 0.24
                        glow: 1
                        shade: 0
                        opacity: Math.max(0.55, 1 - u.far * u.far) * Math.min(1, ((u.p?.z ?? 0) - 3) / 10)
                    }
                    Column {
                        visible: sb.visible && map.carded?.id !== u.modelData.id
                        opacity: map.ui
                        x: (u.p?.x ?? 0) - win.ox + sb.width / 2 + 6
                        y: (u.p?.y ?? 0) - win.oy - 8
                        Hud { text: map.sysName(u.modelData.id) + (u.modelData.id === map.current ? "  ◂" : ""); color: u.picked ? Theme.accent : Theme.fg; opacity: u.picked || map.aimed === u.modelData ? 1 : 0.6 }
                        Hud { text: map.nameOf(u.modelData.ws); font.pixelSize: 10; color: Theme.dim; visible: text !== "" && (u.picked || map.aimed === u.modelData || u.modelData.id === map.current) }
                    }
                }
            }

            // known systems you can't see get a marker on the edge pointing at them (tab still cycles to them)
            Repeater {
                model: win.main ? map.used : []
                Item {
                    id: mk
                    required property var modelData
                    readonly property var q: map.rel(modelData.pos)
                    readonly property var p: map.project(modelData.pos)
                    readonly property real lx: p ? p.x - win.ox : 0
                    readonly property real ly: p ? p.y - win.oy : 0
                    readonly property bool off: !p || lx < 40 || ly < 40 || lx > win.width - 40 || ly > win.height - 40
                    // behind you the camera space x/y still point the short way round
                    readonly property real ang: Math.atan2(-mk.q[1], mk.q[0])
                    readonly property real k: Math.min((win.width / 2 - 36) / Math.max(1e-3, Math.abs(Math.cos(ang))),
                                                       (win.height / 2 - 36) / Math.max(1e-3, Math.abs(Math.sin(ang))))
                    visible: off && !map.busy
                    opacity: map.ui
                    x: map.cx - win.ox + Math.cos(ang) * k
                    y: map.cy - win.oy + Math.sin(ang) * k
                    z: 11
                    Rectangle { anchors.centerIn: parent; width: 6; height: 6; rotation: 45; antialiasing: true; color: mk.modelData.id === map.current ? Theme.accent : Theme.fg }
                    Rectangle {
                        x: Math.cos(mk.ang) * 9 - 3; y: Math.sin(mk.ang) * 9 - 0.5
                        width: 6; height: 1; rotation: mk.ang * 180 / Math.PI; antialiasing: true; color: Theme.dim
                    }
                    Hud {
                        x: -Math.cos(mk.ang) * 20 - width / 2
                        y: -Math.sin(mk.ang) * 14 - height / 2
                        text: String(mk.modelData.id).padStart(2, "0")
                        font.pixelSize: 9
                        color: mk.modelData.id === map.current ? Theme.accent : Theme.dim
                    }
                }
            }

            // the open system's planets and moons, the land shader up in orbit so each is exactly the world you'd land on.
            // nearer draws on top
            Repeater {
                model: map.bodies
                Item {
                    id: bd
                    required property var modelData
                    readonly property var p: map.screenOf(modelData)
                    readonly property real rpx: p ? modelData.r * map.bloom * map.cam.f / p.z : 0
                    z: 4 + (p ? 1 - Math.min(1, p.z / 500) : 0)
                    Terrain {
                        id: pl
                        visible: !!bd.p && bd.rpx > 1.2 && bd.p.z < 400
                        width: Math.max(4, bd.rpx / 0.4)
                        height: width
                        x: (bd.p?.x ?? 0) - win.ox - width / 2
                        y: (bd.p?.y ?? 0) - win.oy - height / 2
                        rise: 1
                        clear: 1
                        endR: 0.4
                        kind: bd.modelData.kind === "moon" ? 1 : 0
                        hue: bd.modelData.hue
                        seed: bd.modelData.seed
                        sun: map.sunDir(map.shown(bd.modelData), bd.modelData.star)
                        // the takeoff/landing's own planet only shows once the wallpaper starts handing over
                        opacity: (bd.p ? Math.min(1, (400 - bd.p.z) / 120) : 0) * (map.isTransit(bd.modelData) && map.ascent < 0.995 ? 0 : 1)
                    }
                    Hud {
                        visible: pl.visible && bd.modelData.kind !== "home" && !bd.modelData.natural && map.aimed === bd.modelData
                        x: pl.x + pl.width / 2 + bd.rpx + 8
                        y: pl.y + pl.height / 2 - 7
                        text: bd.modelData.kind === "moon" ? (bd.modelData.special ?? "") : map.appOf(bd.modelData.window)
                        font.pixelSize: 10
                        color: Theme.accent
                    }
                }
            }

            // bracket on whatever the crosshair sits on
            Item {
                readonly property var p: map.aimed && !map.busy ? map.screenOf(map.aimed) : null
                visible: !!p
                x: (p?.x ?? 0) - win.ox
                y: (p?.y ?? 0) - win.oy
                z: 8
                Rectangle { anchors.centerIn: parent; width: 24; height: 24; rotation: 45; color: "transparent"; antialiasing: true; border.width: 1; border.color: Theme.accent }
            }

            // the card next to it
            Item {
                id: cardBox
                readonly property var o: map.carded
                readonly property var p: o ? map.screenOf(o) : null
                visible: !!p && p.x - win.ox > -320 && p.x - win.ox < win.width
                x: p ? Math.min(win.width - 290, p.x - win.ox + 44) : 0
                y: p ? Math.max(20, Math.min(win.height - card.height - 20, p.y - win.oy - 30)) : 0
                z: 10
                Rectangle {
                    id: card
                    width: 250
                    height: info.height + 22
                    color: Theme.alpha(Theme.bg, 0.72)
                    border.width: 1
                    border.color: Theme.alpha(Theme.fg, 0.08)
                    Rectangle { width: 2; height: parent.height; color: Theme.accent }
                    Column {
                        id: info
                        readonly property var o: cardBox.o
                        readonly property string kind: o?.kind ?? ""
                        readonly property var wins: kind === "ws" ? o.ws.toplevels.values : []
                        x: 16
                        y: 11
                        width: parent.width - 30
                        spacing: 4
                        Hud {
                            font.pixelSize: 12
                            color: Theme.fg
                            text: info.kind === "ws" ? map.sysName(info.o.id) + (info.o.id === map.current ? "  (you)" : "")
                                : info.kind === "planet" ? map.appOf(info.o.window) || "planet"
                                : info.kind === "moon" ? (info.o.natural ? "moon" : info.o.special)
                                : info.kind === "home" ? (info.o.sys.kind === "ws" ? map.sysName(info.o.sys.id) + " home" : "uncharted world")
                                : info.kind ? "uncharted system" : ""
                        }
                        Hud {
                            color: Theme.accent
                            text: info.kind === "ws" ? (info.wins.length + 1) + (info.wins.length ? " planets" : " planet")
                                : info.kind === "planet" ? "planet of " + map.sysName(info.o.wsid)
                                : info.kind === "moon" ? (info.o.natural ? "of " + (info.o.sys.kind === "ws" ? map.sysName(info.o.sys.id) : "an uncharted world") : "scratchpad moon")
                                : info.kind === "home" ? (info.o.sys.kind === "ws" ? "your world" : "a new world, new colours")
                                : info.kind ? "1 planet  //  unexplored" : ""
                        }
                        Repeater {
                            model: info.wins.slice(0, 8)
                            Hud {
                                caps: false; elide: Text.ElideRight; font.pixelSize: 11; color: Theme.dim
                                required property var modelData
                                width: info.width
                                text: "◦ " + (map.appOf(modelData) || "window") + (modelData.title ? "  " + modelData.title : "")
                            }
                        }
                        Hud { caps: false; elide: Text.ElideRight; font.pixelSize: 11; color: Theme.dim; width: info.width; visible: info.kind === "planet"; text: info.o?.window?.title ?? "" }
                        Hud {
                            color: Theme.alpha(Theme.fg, 0.4)
                            font.pixelSize: 9
                            text: !info.kind ? "" : info.o.star ? "click  land" : info.o.id === map.sel?.id ? "click  land here" : "click  fly to it"
                        }
                    }
                }
            }

            // crosshair on the screen you opened it on
            Item {
                visible: win.main
                x: map.cx - win.ox
                y: map.cy - win.oy
                z: 12
                opacity: map.ui * 0.7
                Rectangle { anchors.centerIn: parent; width: 18; height: 18; radius: 9; color: "transparent"; border.width: 1; border.color: Theme.fg }
                Rectangle { anchors.centerIn: parent; width: 2; height: 2; radius: 1; color: Theme.fg }
            }

            Hud {
                visible: win.main
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 26
                opacity: map.ui * (map.idle ? 0 : 1)
                Behavior on opacity { NumberAnimation { duration: 600 } }
                text: "mouse  look    wasd  fly    shift  fast    q e  turn    tab  next system    space  home    click  select    esc  land"
                color: Theme.alpha(Theme.fg, 0.45)
            }

            }

            // the real wallpaper rising into orbit and coming back down. space goes see-through so it hands over to the map
            Terrain {
                anchors.fill: parent
                // above every star, label and card so nothing shows through the transition
                z: 50
                visible: map.ground * map.veil > 0
                opacity: map.ground * Math.min(1, map.veil * 2)
                ws: map.landWs
                screenX: win.ox
                hue: map.landHue
                seed: map.landSeed
                rise: map.ascent
                clear: 1
                orbit: win.main ? 1 : 0
                endR: map.endR
                // same sun the map's copy gets, so the handoff doesn't flip the lighting
                sun: map.sunDir(map.transitLight?.[0], map.transitLight?.[1])
                moonless: win.modelData === Hypr.moonScreen ? 0 : 1
                moonEnd: win.main && !moonless ? map.moonEnd : Qt.vector4d(0, 0, 0, 0)
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.BlankCursor
                onPositionChanged: m => map.look(m.x + win.ox, m.y + win.oy)
                onClicked: map.act()
            }
            Item {
                focus: win.main
                Keys.onPressed: e => map.key(e, true)
                Keys.onReleased: e => map.key(e, false)
            }
        }
    }
}
