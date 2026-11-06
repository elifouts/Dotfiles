.pragma library
const noise = "#$%&*+=<>/\\|01"
function frame(from, to, k, all) {
    if (k >= 1) return to
    const n = Math.max(from.length, to.length), lead = k * (n + 5)
    let out = ""
    for (let i = 0; i < n; i++) {
        const t = to[i] ?? "", f = from[i] ?? ""
        if (i < lead - 5 || (!all && t === f)) out += i < lead ? t : f
        else if (i < lead) out += /\s/.test(t || f) ? t || f : noise[Math.floor(Math.random() * noise.length)]
        else out += f
    }
    return out.replace(/\s+$/, "")
}
function ms(len, first) { return first ? 180 + Math.min(len, 30) * 9 : 120 + Math.min(len, 30) * 6 }
let lastAt = 0, inBurst = 0
function stagger() {
    const now = Date.now()
    if (now - lastAt > 60) inBurst = 0
    lastAt = now
    return Math.min(inBurst++ * 12, 150)
}
