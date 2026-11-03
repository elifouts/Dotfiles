.pragma library
// the launcher's ripple: settled new text, a band of noise, then whatever was there before. k goes 0..1
// same chars on both sides don't scramble (so a clock tick only ripples the digit that changed), all = scramble them anyway like the launcher
const noise = "#$%&*+=<>/\\|01"
function frame(from, to, k, all) {
    if (k >= 1) return to
    const n = Math.max(from.length, to.length), lead = k * (n + 5)
    let out = ""
    for (let i = 0; i < n; i++) {
        const t = to[i] ?? "", f = from[i] ?? ""
        if (i < lead - 5 || (!all && t === f)) out += i < lead ? t : f
        else if (i < lead) out += (t || f) === " " ? " " : noise[Math.floor(Math.random() * noise.length)]
        else out += f
    }
    return out.replace(/\s+$/, "")
}
// first show types out slower than a change, so you actually see it shuffle in
function ms(len, first) { return first ? 260 + Math.min(len, 30) * 16 : 160 + Math.min(len, 30) * 9 }
// things that show up together cascade like the launcher rows instead of all decoding at once
let lastAt = 0, inBurst = 0
function stagger() {
    const now = Date.now()
    if (now - lastAt > 60) inBurst = 0
    lastAt = now
    return Math.min(inBurst++ * 30, 360)
}
