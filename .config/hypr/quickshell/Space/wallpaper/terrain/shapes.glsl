// hills
float roll(float x, float s) {
    return sin(x * 1.3 + h1(s) * 6.3) * 0.5 + sin(x * 2.9 + h1(s + 1.0) * 6.3) * 0.25 + sin(x * 6.1 + h1(s + 2.0) * 6.3) * 0.08;
}
float sharp(float x, float s) {
    return 0.55 - abs(roll(x * 0.6, s + 5.0)) * 1.3;
}
float hillRaw(float x, float R, float H) {
    float p = abs(x - floor(x / 5.0 + 0.5) * 5.0);
    return 0.17 + roll(x * 0.8, 11.0) * 0.03 * H + 0.12 * (1.0 + R * 0.4) * H * (1.0 - smoothstep(0.0, 1.2, p));
}
float ridgeH(float xx, float k, float s, float m, float H) {
    return 0.28 - k * 0.03 + mix(roll(xx, s), sharp(xx, s), m) * (0.04 + k * 0.02) * H * (1.0 + m * 0.8);
}
float under(float y, float h) {
    float aa = fwidth(y) * 0.9;
    return smoothstep(h + aa, h - aa, y);
}
// rocks
float rockD(vec2 p, float k, float nf) {
    float best = -1e3, tl = (h1(k + 30.0) - 0.5) * 0.5;
    for (int i = 0; i < 9; i++) {
        if (float(i) >= nf) break;
        float a = 3.14159 * (float(i) + 0.5 + (h1(k + float(i)) - 0.5) * 0.7) / nf + tl;
        vec2 n = vec2(cos(a), sin(a));
        float di = dot(p - vec2(0.0, 0.22), n) - (0.5 + 0.28 * h1(k + float(i) + 7.0));
        best = max(best, di);
    }
    return max(best, -p.y);
}
float pebbles(float x, float y, float ground, float cx, float span, float sz, float key, float aa) {
    float lift = y - ground, d = 1e3;
    if (abs(x - cx) > span + sz * 2.5 || lift > sz * 1.5 || lift < -aa * 3.0) return 0.0;
    for (int i = 0; i < 5; i++) {
        float fi = float(i);
        if (h1(key + fi * 3.1) > 0.7) continue;
        float r = sz * (0.4 + 0.7 * h1(key + fi * 5.3 + 1.0)), px = cx + (h1(key + fi * 7.7 + 2.0) - 0.5) * 2.0 * span;
        float sq = 1.0 + 0.7 * h1(key + fi + 4.0);
        d = min(d, rockD(vec2((x - px) / sq, lift + r * 0.08 + aa * 2.0) / r, key + fi * 13.0, 4.0 + floor(h1(key + fi + 6.0) * 4.0)) * r);
    }
    return smoothstep(aa, -aa, d) * smoothstep(-aa * 3.0, -aa, lift);
}
float rockBed(float x, float y, float ground, float dens, float w, float sz, float s, float ex, float er, float aa) {
    float c = floor(x / w);
    if (dens <= 0.0 || h1(c + s) > dens * 0.6) return 0.0;
    float cx = (c + 0.5 + (h1(c + s + 1.0) - 0.5) * 0.5) * w;
    if (abs(cx - ex) < er) return 0.0;
    return pebbles(x, y, ground, cx, sz * 6.0, sz * (0.6 + 0.8 * h1(c + s + 2.0)), c * 7.0 + s, aa);
}
// shape tools
float sdBox(vec2 p, vec2 b, float r) {
    vec2 d = abs(p) - b + r;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
}
float sdTaper(vec2 p, vec2 a, vec2 b, float ra, float rb) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - mix(ra, rb, h);
}
float smin(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * k * 0.25;
}
// bush
float lump(vec2 p, vec2 c, vec2 r, float k) {
    float m = min(r.x, r.y), d = length((p - c) / r) * m - m * 0.7;
    for (int i = 0; i < 6; i++) {
        float fi = float(i), a = fi * 1.05 + h1(k + fi) * 0.8;
        vec2 o = c + vec2(cos(a), sin(a)) * r * (0.4 + 0.35 * h1(k + fi + 5.0));
        o.y = max(o.y, c.y - r.y * 0.3);
        d = smin(d, length(p - o) - m * (0.35 + 0.25 * h1(k + fi + 9.0)), m * 0.25);
    }
    vec2 q = (p - c) / r;
    return d - m * 0.07 * abs(sin(atan(q.y, q.x) * 9.0 + k));
}
// trees
float trees(float x, float y, float ground, float dens, float s, float sc, float xs, float ex, float er, vec3 oc) {
    float cw = 0.033 * sc * xs, ax = fwidth(x) * 1.2 / xs, ay = fwidth(y) * 0.9, lift = y - ground;
    if (lift < -ay * 2.0 || lift > sc * 0.23 + ay || dens <= 0.0) return 0.0;
    float ci = floor(x / cw), cov = 0.0, L = 0.6, par = floor(h1(s + 0.7) * 2.0);
    for (int j = -2; j <= 2; j++) {
        float c = ci + float(j), k = c + s, at = (c + 0.5) * cw / xs;
        float dd = 9.0, T = 0.0, g = 0.0, cxs = 0.0;
        for (int q = -1; q <= 1; q++) {
            float gq = floor(at / L) + float(q), major = mod(gq + par, 2.0), pick = h1(gq * 7.0 + s);
            float Tq = major > 0.5 ? step(0.55, pick) : 2.0 + step(0.55, pick);
            float R = Tq == 0.0 ? 0.12 + 0.08 * h1(gq + s + 1.0) : Tq == 1.0 ? 0.035 + 0.035 * h1(gq + s + 1.0) : 0.03;
            float sx0 = (gq + 0.5) * L + (h1(gq + s + 2.0) - 0.5) * 0.08;
            float dq = abs(at - sx0) / R + (step(min(dens * (1.0 + major * 2.0), 1.0), h1(gq + s + 3.0)) + step(2.5, Tq)) * 9.0;
            if (dq < dd) { dd = dq; T = Tq; g = gq; cxs = sx0; }
        }
        float lone = step(abs(at - cxs), cw / xs * 0.5), bsd = h1(g + s + 78.0) < 0.5 ? -1.0 : 1.0;
        float isBo = T == 2.0 && s == 0.0 && h1(g + s + 77.0) < 0.6 ? step(abs(at - cxs - bsd * cw / xs * 1.3), cw / xs * 0.5) : 0.0;
        float twin = T == 2.0 && isBo + lone < 0.5 && h1(g + s + 79.0) < 0.6 ? step(abs(at - cxs + bsd * cw / xs * 1.2), cw / xs * 0.5) : 0.0;
        float pT = T == 0.0 ? 0.95 * smoothstep(1.05, 0.75, dd) : T == 1.0 ? 0.7 * step(dd, 1.0) : max(lone, twin);
        float isT = step(h1(k), pT) * (1.0 - isBo);
        float isB = step(h1(k + 40.0), T == 2.0 ? 0.5 * step(dd, 2.2) : 0.3 * step(dd, 1.5) * step(0.9, dd)) * (1.0 - isT) * (1.0 - isBo);
        float isR = step(h1(k + 45.0), T == 2.0 ? 0.55 * step(dd, 4.0) : 0.35 * step(dd, 1.7) * step(0.8, dd)) * (1.0 - isT) * (1.0 - isB) * (1.0 - isBo);
        if ((isT + isB + isR + isBo) * step(er, abs(at * xs - ex) / xs) < 0.5) continue;
        if (oc.x > 0.0 && ridgeH(at * xs, 1.0, 6.0, oc.y * 0.5, oc.z) < 0.18 + 0.03 * oc.z) continue;
        float hr = h1(k + 4.0), sp = h1(k + 30.0) < 0.8 ? floor(h1(g + s + 5.0) * 2.99) : floor(h1(k + 31.0) * 2.99);
        sp = T == 1.0 ? sp : T == 2.0 ? 1.0 : max(sp, 1.0);
        float pf = T == 0.0 ? 1.0 - clamp(dd, 0.0, 1.0) : 0.5;
        float th = isBo > 0.5 ? sc * (0.026 + 0.008 * hr) : isR > 0.5 ? sc * (0.006 + 0.005 * hr) : isB > 0.5 ? sc * (0.013 + 0.01 * hr) : sc * (0.035 + 0.09 * hr * hr) * mix(0.8, 1.45, pf) * (sp == 0.0 ? 1.15 : 1.0) * (T == 2.0 ? (twin > 0.5 ? 0.7 : 1.3) + hr * 0.3 : 1.0);
        float cx = (c + 0.5 + (h1(k + 7.0) - 0.5) * (isBo > 0.5 ? 0.2 : 0.8)) * cw;
        float u = lift / th, an = ax / th * 1.3;
        vec2 p = vec2((x - cx) / xs / th, u);
        float d;
        if (isBo > 0.5) {
            d = min(rockD(vec2(p.x / 1.35, p.y + 0.05), k + 50.0, 8.0), rockD((p - vec2(bsd * 1.25, -0.04)) / 0.42, k + 60.0, 6.0) * 0.42);
        } else if (isR > 0.5) {
            d = 1e3;
            for (int ri = 0; ri < 3; ri++) {
                float fr = float(ri), kr = k * 3.0 + fr * 17.0;
                if (ri > 0 && h1(kr + 1.0) > 0.6) continue;
                float rs = ri == 0 ? 1.0 : 0.35 + 0.4 * h1(kr + 2.0), sq = 0.9 + 0.8 * h1(kr + 3.0);
                vec2 rp = vec2((p.x - (ri == 0 ? 0.0 : (h1(kr + 4.0) - 0.5) * 3.2)) / sq, p.y + 0.08) / rs;
                d = min(d, rockD(rp, kr, 4.0 + floor(h1(kr + 5.0) * 5.0)) * rs);
            }
        } else if (isB > 0.5) {
            vec2 r = vec2(1.0 + 0.6 * h1(k + 5.0), 0.6);
            d = smin(lump(p, vec2(0.0, 0.4), r, k), sdBox(p - vec2(0.0, 0.15), vec2(r.x * 0.7, 0.2), 0.0), 0.15);
        } else {
            vec3 W3 = sp == 0.0 ? vec3(0.085, 0.04, 0.55) : sp == 1.0 ? vec3(0.13, 0.12, 0.75) : vec3(0.24, 0.08, 1.0);
            float sx = p.x - (h1(k + 13.0) - 0.5) * (sp == 2.0 ? 0.2 : 0.08) * u * u, dx = abs(sx), side = step(0.0, sx);
            float W = (W3.x + W3.y * h1(k + 11.0)) * (1.35 - hr * 0.45) * (T == 0.0 ? 1.35 : 1.0), N = (sp == 0.0 ? 16.0 : 12.0) + floor(h1(k + 9.0) * 10.0);
            float tb = u * N + dx / W * (sp == 0.0 ? 0.3 : 0.5 + 0.6 * h1(k + 17.0) + (sp == 2.0 ? 0.4 : 0.0)) + side * h1(k + 23.0);
            float v = fract(tb), base = 0.015 + 0.05 * h1(k + 21.0);
            float body = pow(max(1.0 - u, 0.0), W3.z + 0.5 * h1(k + 19.0)) * mix(0.7, 1.0, smoothstep(base, base + 0.25, u)) * step(base, u);
            float hw = W * body * (0.86 + 0.22 * h1(floor(tb) * 1.7 + side * 31.0 + k * 3.1)) * (1.0 - 0.2 * smoothstep(0.0, 1.0, v));
            float bot = base + (0.01 + 0.05 * n1(dx / W * 5.0 + side * 7.0 + k)) * smoothstep(0.25, 1.0, dx / W);
            d = max(min(max(dx - hw, (bot - u) * 0.6), max(dx - 0.012, u - base - 0.1)), u - 1.0);
        }
        if (isR < 0.5) {
        float mw = isBo > 0.5 ? 1.9 : isB > 0.5 ? 1.5 : 0.34 + 0.12 * h1(k + 26.0), mh = isBo > 0.5 ? 0.08 : isB > 0.5 ? 0.1 : 0.04 + 0.03 * h1(k + 27.0), ax2 = abs(p.x) / mw;
        d = min(d, max(u - mh * (1.0 - ax2 * ax2), abs(p.x) - mw));
        if (ax2 < 1.7) {
            float gq = p.x * 30.0;
            for (int b = -1; b <= 1; b++) {
                float gi = floor(gq) + float(b), gx2 = abs(gi / 30.0) / mw;
                float bh = (mh * max(1.0 - gx2 * gx2, 0.0) + (0.03 + 0.08 * h1(gi + k)) * smoothstep(1.7, 0.6, gx2)) * step(h1(gi + k + 2.0), 0.85);
                float bu = clamp(u / max(bh, 1e-4), 0.0, 1.0);
                float bc = gi + 0.5 + (h1(gi + k + 1.0) - 0.5) * 1.6 * bu * bu;
                d = min(d, max((abs(gq - bc) - 0.33 * (1.0 - bu * bu)) / 30.0, u - bh));
            }
        }
        }
        float t = smoothstep(an, -an, d) * smoothstep(-ay * 3.0, -ay, lift);
        cov = max(cov, t);
    }
    return cov;
}
// habitats
vec3 habSize(float k) {
    float c = h1(k + 1.0), big = step(0.75, c), small = step(c, 0.35);
    float r = mix(mix(0.028, 0.038, big), 0.017, small) * (0.9 + 0.2 * h1(k + 2.0));
    float nm = small > 0.5 ? step(0.5, h1(k + 3.0)) : big > 0.5 ? 2.0 : 1.0;
    return vec3(r, nm, big - small);
}
vec2 habitat(vec2 p, float aa, float k) {
    vec3 hs = habSize(k);
    float r = hs.x, d = (length(p / vec2(r, r * (0.8 + 0.1 * h1(k + 4.0)))) - 1.0) * r * 0.85, lights = exp(-length((p - vec2(-0.2 * r, 0.3 * r)) * vec2(0.6, 1.0)) * 900.0) * 0.8;
    float x0 = r * 0.9;
    for (int i = 0; i < 2; i++) {
        if (float(i) >= hs.y) break;
        float w = 0.014 + 0.008 * h1(k + 5.0 + float(i)), hh = 0.007 + 0.004 * h1(k + 7.0 + float(i));
        d = min(d, sdBox(p - vec2(x0 + 0.004, 0.004), vec2(0.006, 0.003), 0.001));
        float cx = x0 + 0.009 + w;
        d = min(d, sdBox(p - vec2(cx, hh), vec2(w, hh), 0.005));
        for (int j = 0; j < 3; j++) lights += exp(-length((p - vec2(cx - w * 0.5 + float(j) * w * 0.5, hh * 1.1)) * vec2(1.0, 1.8)) * 1400.0);
        x0 = cx + w;
    }
    float xl = -r * 0.9;
    if (hs.z > 0.5) {
        float r2 = r * 0.6;
        d = min(d, sdBox(p - vec2(xl - 0.004, 0.004), vec2(0.006, 0.003), 0.001));
        d = min(d, (length((p - vec2(xl - 0.008 - r2, 0.0)) / vec2(r2, r2 * 0.85)) - 1.0) * r2 * 0.85);
        lights += exp(-length(p - vec2(xl - 0.008 - r2, r2 * 0.4)) * 1200.0) * 0.6;
        xl -= 0.01 + r2 * 2.0;
    }
    if (h1(k + 9.0) < 0.3 + 0.5 * (hs.z + 1.0)) {
        float tx = xl - 0.012, th = mix(0.035, 0.09, h1(k + 10.0)) * (1.0 + 0.3 * hs.z);
        d = min(d, sdTaper(p, vec2(tx, 0.0), vec2(tx, th), 0.0042, 0.0016));
        d = min(d, sdBox(p - vec2(tx, th * 0.9), vec2(0.0052, 0.0034), 0.0016));
        vec2 dc = vec2(tx + 0.0075, th * (0.62 + 0.12 * h1(k + 13.0)));
        d = min(d, min(sdBox(p - vec2(tx + 0.0035, dc.y), vec2(0.0035, 0.0006), 0.0), max(length(p - dc) - 0.0038, dc.x - 0.0008 - p.x)));
        d = min(d, sdBox(p - vec2(tx, th + 0.01), vec2(0.0007, 0.012), 0.0));
        lights += exp(-length(p - vec2(tx, th + 0.022)) * 900.0) * 1.4;
    }
    if (h1(k + 11.0) < 0.5) d = min(d, sdBox(p - vec2(xl + 0.002, 0.008 + 0.006 * h1(k + 12.0)), vec2(0.0012, 0.008 + 0.006 * h1(k + 12.0)), 0.0));
    d = max(d, -p.y);
    return vec2(smoothstep(aa, -aa, d), lights);
}
// grass
float grass(float x, float y, float ground, float dens, float s) {
    float gx = x * 240.0, ax = fwidth(gx) * 1.2, ay = fwidth(y) * 0.9, lift = y - ground, cov = 0.0;
    if (lift < -ay * 3.0 || lift > 0.03 || dens <= 0.0) return 0.0;
    float clump = smoothstep(1.0 - dens, 1.0 - dens + 0.3, n1(x * 7.0 + s) * 0.7 + n1(x * 23.0 + s + 9.0) * 0.3);
    if (clump < 0.05) return 0.0;
    float tall = smoothstep(0.45, 0.85, n1(x * 2.6 + s + 40.0)), wind = (n1(x * 1.7 + s + 50.0) - 0.5) * 1.6;
    for (int j = -3; j <= 3; j++) {
        float gi = floor(gx) + float(j);
        for (int b = 0; b < 2; b++) {
            float hb = gi * 2.0 + float(b) + s;
            float on = step(h1(hb + 3.0), clump * (b == 0 ? 0.9 : 0.6 * clump));
            float th = mix(0.0025, 0.007, h1(hb + 1.0)) * (0.5 + 0.7 * clump) * mix(1.0, 3.0, tall * h1(hb + 6.0)) * on;
            float u = clamp(lift / max(th, 1e-5), 0.0, 1.0);
            float lean = clamp((wind + h1(hb + 2.0) - 0.5) * (1.0 + tall * 1.5), -2.5, 2.5);
            float w = (0.2 + 0.08 * tall) * (1.0 - u * u);
            cov = max(cov, smoothstep(w + ax, w - ax, abs(gx - gi - h1(hb + 4.0) - lean * u * u)) * smoothstep(th + ay, th - ay, lift) * step(0.001, th));
        }
    }
    return cov * smoothstep(-ay * 3.0, -ay, lift);
}
// ship
float shipShape(vec2 q, float s, float aa, float legs) {
    vec2 p = q / s;
    aa = max(aa / s, 1e-4);
    float py = abs(p.y);
    float hull = sdTaper(vec2(p.x, py), vec2(-0.1, 0.0), vec2(0.12, 0.0), 0.075, 0.075);
    hull = smin(hull, sdTaper(vec2(p.x, py), vec2(0.1, 0.0), vec2(0.52, 0.0), 0.075, 0.014), 0.05);
    hull = -smin(-hull, p.y + 0.03, 0.05);
    float d = smin(hull, sdTaper(p, vec2(0.02, 0.05), vec2(-0.04, 0.16), 0.055, 0.02), 0.04);
    d = smin(d, sdTaper(p, vec2(0.07, -0.02), vec2(-0.07, -0.12), 0.045, 0.012), 0.08);
    float l = min(sdTaper(p, vec2(0.3, -0.03), vec2(0.315, -0.08), 0.011, 0.007), sdTaper(p, vec2(0.28, -0.082), vec2(0.35, -0.082), 0.006, 0.006));
    d = min(d, mix(1e3, l, legs));
    return smoothstep(aa, -aa, d);
}
// mountains
float mountH(float xp, float R, float H) {
    float soft = n1(xp * 2.0) * 0.6 + n1(xp * 5.0) * 0.25 + abs(n1(xp * 11.0) - 0.5) * 0.1;
    float rid = 1.0 - abs(n1(xp * 1.3 + 3.0) * 2.0 - 1.0);
    float hard = rid * rid * 0.7 + (1.0 - abs(n1(xp * 3.7) * 2.0 - 1.0)) * 0.22 + n1(xp * 13.0) * 0.06;
    return 0.27 + mix(soft * 0.08, hard * 0.24, R) * H;
}
float groundH(float L, float xx, float k, float s, float m, float R, float H) {
    return L < 0.5 ? mountH(xx, R, H) : L < 1.5 ? ridgeH(xx, k, s, m, H) : hillRaw(xx, R, H);
}
// astronaut
float astroD(vec2 p, float pose) {
    if (pose > 3.5) {
        float e = smin(sdTaper(p, vec2(0.0, 0.42), vec2(0.21, 0.43), 0.085, 0.072), sdTaper(p, vec2(0.21, 0.43), vec2(0.24, 0.07), 0.072, 0.062), 0.02);
        e = min(e, smin(sdTaper(p, vec2(-0.02, 0.4), vec2(0.18, 0.45), 0.08, 0.07), sdTaper(p, vec2(0.18, 0.45), vec2(0.17, 0.07), 0.07, 0.06), 0.02));
        e = smin(e, min(sdBox(p - vec2(0.27, 0.038), vec2(0.08, 0.04), 0.025), sdBox(p - vec2(0.2, 0.038), vec2(0.08, 0.04), 0.025)), 0.02);
        e = smin(e, sdTaper(p, vec2(0.0, 0.43), vec2(0.04, 0.62), 0.13, 0.145), 0.05);
        e = smin(e, sdBox(p - vec2(-0.14, 0.58), vec2(0.1, 0.2), 0.05), 0.03);
        e = smin(e, length(p - vec2(0.1, 0.65)) - 0.085, 0.03);
        e = smin(e, min(sdTaper(p, vec2(0.1, 0.64), vec2(0.2, 0.5), 0.065, 0.058), sdTaper(p, vec2(0.2, 0.5), vec2(0.3, 0.52), 0.058, 0.05)), 0.02);
        e = min(e, length(p - vec2(0.31, 0.52)) - 0.055);
        return smin(e, length((p - vec2(0.08, 0.82)) / vec2(1.0, 0.94)) * 0.97 - 0.115, 0.03);
    }
    if (pose > 2.5) {
        vec2 q = vec2(abs(p.x), p.y);
        float e = sdTaper(q, vec2(0.065, 0.43), vec2(0.105, 0.07), 0.085, 0.065);
        e = smin(e, sdBox(q - vec2(0.115, 0.038), vec2(0.06, 0.04), 0.025), 0.03);
        e = smin(e, sdBox(p - vec2(0.0, 0.55), vec2(0.15, 0.15), 0.08), 0.05);
        e = smin(e, sdBox(p - vec2(0.0, 0.64), vec2(0.155, 0.19), 0.045), 0.02);
        e = smin(e, length(q - vec2(0.16, 0.68)) - 0.075, 0.03);
        e = smin(e, min(sdTaper(q, vec2(0.19, 0.66), vec2(0.225, 0.42), 0.068, 0.058), length(q - vec2(0.228, 0.38)) - 0.055), 0.02);
        return smin(e, length(p - vec2(0.0, 0.855)) - 0.115, 0.03);
    }
    float d = smin(sdTaper(p, vec2(-0.04, 0.44), vec2(-0.07, 0.25), 0.085, 0.072), sdTaper(p, vec2(-0.07, 0.25), vec2(-0.085, 0.07), 0.072, 0.062), 0.02);
    d = min(d, smin(sdTaper(p, vec2(0.05, 0.44), vec2(0.09, 0.26), 0.085, 0.072), sdTaper(p, vec2(0.09, 0.26), vec2(0.1, 0.07), 0.072, 0.062), 0.02));
    d = smin(d, min(sdBox(p - vec2(-0.06, 0.038), vec2(0.08, 0.04), 0.025), sdBox(p - vec2(0.125, 0.038), vec2(0.08, 0.04), 0.025)), 0.02);
    d = smin(d, sdTaper(p, vec2(0.0, 0.46), vec2(0.01, 0.65), 0.13, 0.145), 0.05);
    d = smin(d, sdBox(p - vec2(-0.17, 0.6), vec2(0.1, 0.2), 0.05), 0.03);
    d = smin(d, length(p - vec2(0.07, 0.68)) - 0.085, 0.03);
    vec2 elb = pose < 0.5 ? vec2(0.12, 0.53) : pose < 1.5 ? vec2(0.18, 0.58) : vec2(0.21, 0.7);
    vec2 hand = pose < 0.5 ? vec2(0.13, 0.4) : pose < 1.5 ? vec2(0.29, 0.63) : vec2(0.16, 0.86);
    d = smin(d, min(sdTaper(p, vec2(0.08, 0.67), elb, 0.065, 0.058), sdTaper(p, elb, hand, 0.058, 0.05)), 0.02);
    d = min(d, length(p - hand) - 0.055);
    if (pose > 0.5 && pose < 1.5) d = min(d, min(sdBox(p - vec2(0.34, 0.645), vec2(0.08, 0.028), 0.014), sdBox(p - vec2(0.29, 0.6), vec2(0.02, 0.045), 0.01)));
    return smin(d, length((p - vec2(0.035, 0.855)) / vec2(1.0, 0.94)) * 0.97 - 0.115, 0.03);
}
vec4 astro(vec2 p, float aa, float pose, float lx) {
    float d = astroD(p, pose), cv = smoothstep(aa, -aa, d);
    float rim = cv * smoothstep(-aa, aa, astroD(p + normalize(vec2(lx, 0.6)) * 0.03, pose));
    vec2 hc = pose > 3.5 ? vec2(0.08, 0.82) : vec2(0.035, 0.855);
    float hd = length((p - hc) / vec2(1.0, 0.94));
    float visor = pose > 2.5 && pose < 3.5 ? 0.0 : smoothstep(0.03, 0.012, abs(p.y - hc.y - 0.005)) * smoothstep(0.04, 0.1, p.x - hc.x + 0.035) * step(hd, 0.115);
    float li = pose > 2.5 && pose < 3.5 ? exp(-length(p - vec2(0.0, 0.7)) * 120.0) * 0.6 : exp(-length(p - vec2(-0.27, 0.66)) * 120.0) * 0.6;
    li += pose > 0.5 && pose < 1.5 ? exp(-length(p - vec2(0.42, 0.645)) * 70.0) * 1.2 : 0.0;
    return vec4(cv, visor, rim, li);
}
vec3 astroPaint(vec3 col, vec3 body, vec2 p, float aa, float pose, float lx, float gl, out float cov) {
    vec4 a = astro(p, aa, pose, lx);
    vec3 accent = mix(horizon.rgb, warm.rgb, 0.5);
    col = mix(col, body + (accent * a.z * 0.1 + mix(accent, vec3(1.0), 0.3) * a.y * 0.35) * gl, a.x);
    cov = a.x;
    return col + mix(warm.rgb, vec3(1.0), 0.3) * a.w * 0.35 * gl;
}
// peak finder
float frontH(float L, float k, float sx, float R, float H) {
    if (L > 1.5) return 0.0;
    float f = hillRaw(sx + pan * 0.6, R, H);
    for (int i = 0; i < 3; i++) {
        float k2 = float(i) / 2.0;
        if (L < 0.5 || k2 > k + 0.01) f = max(f, ridgeH(sx * (2.0 - k2 * 0.6) + pan * (0.12 + k2 * 0.25), k2, float(i) * 3.0, R * (1.0 - k2 * 0.5), H));
    }
    return f;
}
vec3 peakAt(float L, float xx, float y, float hHere, float xs, float cell, float jit, float sz, float k, float s, float m, float R, float H, float key) {
    float rc = floor(xx / cell + 0.5), pxr = (rc + (h1(rc + key) - 0.5) * jit) * cell;
    if (abs(xx - pxr) > 1.4 * xs || h1(rc + key + 1.0) > 0.95 || y < hHere - 0.01 || y > hHere + sz * 1.2 + 0.03) return vec3(0.0);
    float best = -1.0, bx = pxr, bi = 0.0, po = L < 0.5 ? pan * 0.06 : L < 1.5 ? pan * (0.12 + k * 0.25) : pan * 0.6, ps = L < 0.5 ? 1.6 : xs;
    float h0 = -1.0, hp = -1.0;
    for (int t = 0; t < 34; t++) {
        float sx = pxr + (float(t) - 16.5) * 0.08 * xs, hh = groundH(L, sx, k, s, m, R, H), px = sx - 0.08 * xs;
        if (t > 1 && hp > h0 && hp >= hh && hp > best && hp - frontH(L, k, (px - po) / ps, R, H) > sz * 0.2) { best = hp; bx = px; }
        h0 = hp; hp = hh;
    }
    if (best < 0.0) return vec3(0.0);
    for (int r = 0; r < 3; r++) {
        float c0 = bx, st = 0.02 * xs / pow(5.0, float(r));
        for (int t = 0; t < 9; t++) {
            float sx = c0 + (float(t) - 4.0) * st, hh = groundH(L, sx, k, s, m, R, H);
            if (hh > best) { best = hh; bx = sx; }
        }
    }
    for (int t = 0; t < 47; t++) {
        float sx = bx + (float(t) - 23.0) * 0.08 * xs;
        if (abs(sx - bx) > 0.1 * xs && groundH(L, sx, k, s, m, R, H) > best) return vec3(0.0);
    }
    return vec3(bx, best, 1.0);
}
// landed ship
vec4 shipLanded(vec2 d, float ss, float aa) {
    vec2 g0 = vec2(d.x, d.y - 0.1095 * ss);
    vec2 gp = vec2(0.9976 * g0.x - 0.07 * g0.y, 0.07 * g0.x + 0.9976 * g0.y);
    return vec4(shipShape(gp, ss, aa, 1.0) * step(-0.02 * ss, d.y), gp.y / ss, exp(-length(gp / ss - vec2(0.3, 0.035)) * 45.0), exp(-length((gp / ss - vec2(0.33, -0.09)) * vec2(0.5, 1.0)) * 30.0));
}
// camp items
vec2 campItem(vec2 q, float u, float t, float k, float aa) {
    float d, li = 0.0;
    vec2 lp = vec2(0.0);
    if (t < 1.0) {
        d = sdBox(q - vec2(0.0, 0.5 * u), vec2(0.6 * u, 0.5 * u), 0.08 * u);
        d = h1(k) < 0.5 ? min(d, sdBox(q - vec2(0.15 * u, 1.38 * u), vec2(0.42 * u, 0.38 * u), 0.06 * u)) : d;
    } else if (t < 2.0) {
        d = min(sdBox(q - vec2(0.0, 0.62 * u), vec2(0.3 * u, 0.62 * u), 0.12 * u), sdBox(q - vec2(0.68 * u, 0.5 * u), vec2(0.3 * u, 0.5 * u), 0.12 * u));
    } else if (t < 3.0) {
        d = max(length(q / vec2(1.7, 1.1)) - u, -q.y);
        d = min(d, sdBox(q - vec2(0.0, 1.15 * u), vec2(0.05 * u, 0.25 * u), 0.0));
        lp = vec2(0.75 * u, 0.3 * u); li = 0.8;
    } else if (t < 4.0) {
        d = min(sdBox(q - vec2(0.0, 1.6 * u), vec2(0.05 * u, 1.6 * u), 0.0), sdBox(q - vec2(0.0, 2.6 * u), vec2(0.45 * u, 0.04 * u), 0.0));
        d = min(d, sdTaper(q, vec2(0.0, 2.0 * u), vec2(0.45 * u, 2.3 * u), 0.05 * u, 0.2 * u));
        lp = vec2(0.0, 3.2 * u); li = 1.0;
    } else if (t < 5.0) {
        d = min(sdBox(q - vec2(0.0, 0.8 * u), vec2(0.04 * u, 0.8 * u), 0.0), sdBox(q - vec2(0.12 * u, 1.6 * u), vec2(0.2 * u, 0.07 * u), 0.03 * u));
        lp = vec2(0.22 * u, 1.48 * u); li = 1.4;
    } else if (t < 6.0) {
        vec2 r = q - vec2(0.0, 0.95 * u);
        r = vec2(0.906 * r.x + 0.423 * r.y, -0.423 * r.x + 0.906 * r.y);
        d = min(sdBox(r, vec2(0.9 * u, 0.05 * u), 0.0), sdBox(q - vec2(0.0, 0.45 * u), vec2(0.05 * u, 0.45 * u), 0.0));
        d = h1(k + 3.0) < 0.6 ? min(d, sdBox(r - vec2(0.0, -1.3 * u), vec2(0.9 * u, 0.05 * u), 0.0) + step(0.0, -q.y)) : d;
    } else if (t < 7.0) {
        float wx = abs(q.x) > 0.375 * u ? sign(q.x) * 0.75 * u : 0.0;
        d = length(q - vec2(wx, 0.28 * u)) - 0.27 * u;
        d = min(d, sdBox(q - vec2(wx, 0.5 * u), vec2(0.045 * u, 0.12 * u), 0.0));
        d = min(d, sdBox(q - vec2(0.0, 0.74 * u), vec2(1.05 * u, 0.15 * u), 0.06 * u));
        d = min(d, max(sdBox(q - vec2(0.42 * u, 1.08 * u), vec2(0.42 * u, 0.22 * u), 0.08 * u), dot(q - vec2(0.82 * u, 0.88 * u), vec2(0.82, 0.57))));
        d = min(d, min(sdBox(q - vec2(-0.5 * u, 1.02 * u), vec2(0.42 * u, 0.035 * u), 0.0), sdBox(q - vec2(-0.85 * u, 0.94 * u), vec2(0.035 * u, 0.09 * u), 0.0)));
        d = min(d, min(sdBox(q - vec2(-0.25 * u, 1.3 * u), vec2(0.035 * u, 0.4 * u), 0.0), sdBox(q - vec2(-0.2 * u, 1.72 * u), vec2(0.13 * u, 0.07 * u), 0.03 * u)));
        lp = vec2(1.08 * u, 0.78 * u); li = 1.2;
    } else if (t < 8.0) {
        d = sdBox(q - vec2(0.0, 0.72 * u), vec2(0.95 * u, 0.45 * u), 0.42 * u);
        d = min(d, min(sdBox(q - vec2(0.5 * u, 0.15 * u), vec2(0.06 * u, 0.15 * u), 0.0), sdBox(q - vec2(-0.5 * u, 0.15 * u), vec2(0.06 * u, 0.15 * u), 0.0)));
        d = h1(k + 4.0) < 0.5 ? min(d, sdBox(q - vec2(0.0, 1.62 * u), vec2(0.7 * u, 0.32 * u), 0.3 * u)) : d;
    } else {
        d = sdBox(q - vec2(0.0, 0.6 * u), vec2(0.06 * u, 0.6 * u), 0.0);
        d = min(d, max(length(q - vec2(0.15 * u, 1.55 * u)) - 0.62 * u, -(length(q - vec2(0.42 * u, 1.75 * u)) - 0.62 * u)));
        lp = vec2(0.55 * u, 1.85 * u); li = 0.9;
    }
    return vec2(smoothstep(aa, -aa, d), li * exp(-length(q - lp) / u * 4.0));
}
// camp
vec3 camp(float L, float xx, float y, float xs, float cx, float padH, float f0, float f1, float side, float both, float amt, float off, float u0, float kc, float k, float s, float m, float R, float H, float aa, float big, float slots) {
    vec3 r = vec3(0.0);
    for (int i = 0; i < 10; i++) {
        float fi = float(i), kk = kc * 13.0 + fi, sl = floor(fi * 0.5), sd = mod(fi, 2.0) < 0.5 ? side : -side;
        if (sl >= slots || h1(kk + 64.0) > amt || (sd != side && both < 0.5 && sl > 0.5)) continue;
        float ix = cx + sd * (off + (0.028 * sl + 0.012 * h1(kk + 65.0)) * u0 / 0.009) * xs;
        float gh = mix(groundH(L, ix, k, s, m, R, H), padH, smoothstep(f0, f1, abs(ix - cx) / xs));
        if (L < 1.5 && frontH(L, k, (ix - pan * (0.12 + k * 0.25)) / xs, R, H) > gh - u0 * 0.3) continue;
        vec2 q = vec2((xx - ix) / xs * (h1(kk + 67.0) < 0.5 ? -1.0 : 1.0), y - gh + aa * 2.0);
        float t = floor(h1(kk + 66.0) * (4.99 + big * 4.0));
        t = sl > 0.5 && t == 2.0 ? 0.0 : t;
        vec2 it = campItem(q, u0 * (1.0 + 0.33 * h1(kk + 68.0)), t, kk, aa);
        r.z = mix(r.z, smoothstep(0.0, u0 * 3.0, q.y), it.x);
        r.x = max(r.x, it.x);
        r.y += it.y;
    }
    return r;
}
// atlas marker
vec4 marker(vec2 q, float aa, float mk) {
    q.y += 0.25 * (1.0 - mk);
    q /= mix(vec2(0.66, 1.07), vec2(1.0), mk);
    float dm = (abs(q.x) + abs(q.y) - 0.82) * 0.7071;
    float cov = smoothstep(aa, -aa, dm), ring = cov * smoothstep(-aa, aa, dm + 0.07);
    vec2 qg = q - vec2(0.0, 0.12);
    float ga = (abs(qg.x) / 0.27 + abs(qg.y) / (qg.y >= 0.0 ? 0.31 : 0.56) - 1.0) * (qg.y >= 0.0 ? 0.2 : 0.24);
    float glyph = smoothstep(aa, -aa, ga) * smoothstep(-aa, aa, ga + 0.045);
    glyph = max(glyph, smoothstep(aa, -aa, length(qg) - 0.09));
    float acc = max(ring, glyph);
    vec3 hot = mix(horizon.rgb, warm.rgb, 0.5);
    hot = max(mix(vec3(dot(hot, vec3(0.333))), hot, 1.5), 0.0) * 1.3;
    vec3 c = mix(mix(zenith.rgb, near.rgb, 0.5) * 0.6, hot, acc);
    return vec4(c, cov);
}
