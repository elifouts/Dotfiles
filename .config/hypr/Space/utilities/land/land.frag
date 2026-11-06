#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float pan;
    float zoom;
    float seed;
    float aspect;
    float rise;
    float clear;
    float orbit;
    float endR;
    float kind;
    vec4 zenith;
    vec4 horizon;
    vec4 warm;
    vec4 far;
    vec4 near;
    vec4 moon;
    vec4 sun;
    vec4 shade;
    vec4 moonEnd;
    float lift;
    float glow;
    float moonless;
    float skyFade;
    float wipe;
};

float h1(float n) {
    n = fract(n * 0.1031 + seed * 0.0137);
    n *= n + 33.33;
    n *= n + n;
    return fract(n);
}
float h2(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * 0.1031 + seed * 0.013);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}
float n1(float x) {
    float i = floor(x), f = fract(x);
    return mix(h1(i), h1(i + 1.0), f * f * (3.0 - 2.0 * f));
}
float n2(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(h2(i), h2(i + vec2(1.0, 0.0)), f.x),
               mix(h2(i + vec2(0.0, 1.0)), h2(i + vec2(1.0, 1.0)), f.x), f.y);
}
vec3 perm(vec3 x) {
    return mod((x * 34.0 + 1.0) * x, 289.0);
}
vec3 h3(vec3 p) {
    p = mod(p + floor(seed), 289.0);
    return perm(perm(perm(p) + p.yzx) + p.zxy) / 289.0;
}
float perm1(float x) {
    return mod((x * 34.0 + 1.0) * x, 289.0);
}
float hx(vec3 p) {
    p = mod(p + floor(seed), 289.0);
    return perm1(perm1(perm1(p.x) + p.y) + p.z) / 289.0;
}
float n3(vec3 p) {
    vec3 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(hx(i), hx(i + vec3(1, 0, 0)), f.x), mix(hx(i + vec3(0, 1, 0)), hx(i + vec3(1, 1, 0)), f.x), f.y),
               mix(mix(hx(i + vec3(0, 0, 1)), hx(i + vec3(1, 0, 1)), f.x), mix(hx(i + vec3(0, 1, 1)), hx(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}
vec3 dither() {
    float a = fract(52.9829189 * fract(dot(gl_FragCoord.xy, vec2(0.06711056, 0.00583715))));
    float b = fract(52.9829189 * fract(dot(gl_FragCoord.yx + 17.0, vec2(0.06711056, 0.00583715))));
    return vec3((a + b - 1.0) / 255.0);
}
float keep(float f, float px) {
    return smoothstep(0.5, 0.2, f * px);
}
vec4 planetSurf(vec3 n, float px) {
    vec3 q = n * 1.6 + seed * 0.37;
    vec3 w = vec3(n3(q * 1.3 + 5.0), n3(q * 1.3 + 9.0), n3(q * 1.3 + 13.0)) - 0.5;
    vec3 qw = q + w * 0.7;
    float land = n3(qw) * 0.5 + n3(qw * 2.3) * 0.25 + n3(qw * 5.1) * 0.13
               + (n3(qw * 11.0) - 0.5) * 0.14 * keep(11.0, px) + (n3(qw * 23.0) - 0.5) * 0.08 * keep(23.0, px);
    float coast = smoothstep(0.47, 0.49, land);
    vec3 sea = mix(near.rgb * 1.15, near.rgb * 1.7 + far.rgb * 0.12, smoothstep(0.34, 0.47, land));
    float ridge = 1.0 - abs(n3(qw * 6.0 + 2.0) * 2.0 - 1.0);
    float high = smoothstep(0.56, 0.72, land + ridge * ridge * 0.1);
    vec3 ground = far.rgb * mix(0.82, 1.06, n3(qw * 9.0) * keep(9.0, px) + 0.5 * (1.0 - keep(9.0, px)));
    ground = mix(ground, mix(far.rgb, moon.rgb, 0.3), high * 0.75);
    vec3 s = mix(sea, ground, coast);
    float pole = abs(n.y) + (n3(q * 5.0) - 0.5) * 0.14;
    float ice = smoothstep(0.84, 0.87, pole);
    vec3 white = mix(moon.rgb, vec3(1.0), 0.25);
    s = mix(s, white * 0.92, ice);
    vec3 cq = vec3(n.x * 2.2, n.y * 6.0, n.z * 2.2) + w * 2.2 + seed * 0.53;
    float cl = n3(cq) * 0.6 + n3(cq * 2.7) * 0.3 + (n3(cq * 6.0) - 0.5) * 0.2 * keep(14.0, px);
    float cloud = smoothstep(0.52, 0.72, cl) * 0.75;
    s = mix(s, white * 0.95, cloud);
    return vec4(s, (1.0 - coast) * (1.0 - ice) * (1.0 - cloud));
}
vec2 craters(vec3 n, vec3 L, float sc, float dens, float s) {
    vec3 p = n * sc, i = floor(p);
    vec3 Lt = L - n * dot(n, L);
    vec2 o = vec2(0.0);
    for (int z = -1; z <= 1; z++)
    for (int y = -1; y <= 1; y++)
    for (int x = -1; x <= 1; x++) {
        vec3 c = i + vec3(x, y, z);
        vec3 gap = max(max(c + 0.2 - p, p - c - 0.8), vec3(0.0));
        if (dot(gap, gap) > 0.6889) continue;
        vec3 r = h3(c + s);
        if (r.x > dens) continue;
        vec3 dv = p - (c + 0.2 + 0.6 * h3(c + s + 17.0));
        float rad = mix(0.14, 0.46, r.y * r.y), d = length(dv) / rad;
        float on = smoothstep(1.8, 1.3, d);
        float side = dot(dv / max(length(dv), 1e-4), Lt);
        float wall = smoothstep(0.35, 0.95, d) * smoothstep(1.05, 0.9, d);
        float slope = smoothstep(0.95, 1.1, d) * smoothstep(1.7, 1.1, d);
        o.x += on * (-0.22 * smoothstep(0.9, 0.5, d) + 0.16 * exp(-(d - 1.0) * (d - 1.0) * 20.0) + 0.05 * slope);
        o.y += on * (-side * wall * 0.9 + side * slope * 0.35);
    }
    return o;
}
float moonTone(vec3 n, vec3 L, float px, float crisp) {
    vec3 q = n + seed * 0.21;
    vec3 w = vec3(n3(q * 2.1 + 5.0), n3(q * 2.1 + 9.0), n3(q * 2.1 + 13.0)) - 0.5;
    vec3 qw = q + w * 0.44;
    float maria = smoothstep(0.42, 0.66, n3(qw * 1.7 + 11.0) * 0.55 + n3(qw * 4.1 + 3.0) * 0.3 + n3(qw * 8.3 + 7.0) * 0.15);
    float t = 0.72 - 0.26 * maria + (n3(q * 13.0) - 0.5) * 0.08 * keep(13.0, px) + (n3(q * 31.0) - 0.5) * 0.05 * keep(31.0, px);
    vec2 c = craters(n, L, 4.0, 0.45, 1.0) * smoothstep(0.12, 0.05, 4.0 * px);
    float k9 = smoothstep(0.12, 0.05, 9.0 * px), k18 = smoothstep(0.12, 0.05, 18.0 * px);
    if (k9 > 0.0) c += craters(n, L, 9.0, 0.55, 5.0) * 0.8 * k9;
    if (k18 > 0.0) c += craters(n, L, 18.0, 0.6, 9.0) * 0.55 * k18;
    t += c.x * mix(1.0, 0.5, maria) * mix(0.55, 1.0, crisp) + c.y * 0.22 * mix(0.25, 1.0, crisp);
    return clamp(mix(0.62, t, mix(0.6, 1.0, crisp)), 0.0, 1.0);
}
vec3 moonSurf(vec3 n, vec3 L, float px, float crisp) {
    return moon.rgb * mix(0.3, 0.9, moonTone(n, L, px, crisp));
}
const vec3 skyL = vec3(-0.371, 0.636, 0.742);
float skyFace(vec3 n, vec3 L, float px, float crisp) {
    return 0.05 + 0.17 * moonTone(n, L, px, crisp) * (0.5 + 0.5 * smoothstep(-0.25, 0.7, dot(n, L)));
}
vec3 light(vec3 surf, vec3 n, vec3 L, float air) {
    float ndl = dot(n, L), lit = smoothstep(-0.12, 0.7, ndl);
    surf = mix(shade.rgb + surf * mix(0.34, 0.16, air), surf * (0.6 + 0.6 * lit), lit);
    vec3 a = mix(horizon.rgb, warm.rgb, 0.4) * air + moon.rgb * 0.25 * (1.0 - air);
    return surf + a * pow(1.0 - n.z, 2.6) * (0.25 + 0.75 * smoothstep(-0.3, 0.6, ndl)) * mix(0.35, 0.8, air);
}
float roll(float x, float s) {
    return sin(x * 1.3 + h1(s) * 6.3) * 0.5 + sin(x * 2.9 + h1(s + 1.0) * 6.3) * 0.25 + sin(x * 6.1 + h1(s + 2.0) * 6.3) * 0.08;
}
float hillHeight(float x) {
    float peak = x - floor(x / 5.0 + 0.5) * 5.0;
    return 0.17 + roll(x * 0.8, 11.0) * 0.03 + 0.12 * (1.0 - smoothstep(0.0, 1.4, abs(peak)));
}
float under(float y, float h) {
    float aa = fwidth(y) * 0.9;
    return smoothstep(h + aa, h - aa, y);
}
float pines(float x, float y, float ground, float dens, float s) {
    float tx = x * 30.0, ti = floor(tx), tf = (fract(tx) - 0.5 - (h1(ti + 7.0 + s) - 0.5) * 0.2) * (46.0 / 30.0);
    float ax = fwidth(x) * 46.0 * 1.2, ay = fwidth(y) * 0.9;
    float th = 0.04 + 0.06 * h1(ti + 4.0 + s), lift = y - ground, u = lift / th;
    float tiers = 0.3 + 0.15 * (1.0 - fract(u * 3.2 + 0.2));
    float halfw = u < 0.07 ? 0.035 : (1.0 - u) * tiers;
    float cov = smoothstep(halfw + ax, halfw - ax, abs(tf)) * smoothstep(-ay, ay, lift) * smoothstep(th + ay, th - ay, lift);
    return cov * step(h1(ti + s), dens * (0.3 + 1.4 * n1((ti + 0.5) / 30.0 * 2.3 + s)));
}
float grass(float x, float y, float ground, float dens, float s) {
    float gx = x * 160.0, gi = floor(gx), ax = fwidth(gx) * 1.2, ay = fwidth(y) * 0.9, lift = y - ground;
    float batch = smoothstep(1.0 - dens, 1.0 - dens + 0.1, n1(x * 6.0 + s));
    float th = (0.004 + 0.005 * h1(gi + s + 1.0)) * batch, u = clamp(lift / max(th, 1e-5), 0.0, 1.0);
    float tf = fract(gx) - 0.5 - (h1(gi + s + 2.0) - 0.5) * 0.2;
    float halfw = 0.16 * (1.0 - u);
    return smoothstep(halfw + ax, halfw - ax, abs(tf)) * smoothstep(th + ay, th - ay, lift) * smoothstep(-ay, ay, lift) * step(0.001, batch);
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
float shipShape(vec2 q, float s, float aa) {
    vec2 p = q / s;
    aa = max(aa / s, 1e-4);
    float py = abs(p.y);
    float hull = sdTaper(vec2(p.x, py), vec2(-0.1, 0.0), vec2(0.12, 0.0), 0.075, 0.075);
    hull = smin(hull, sdTaper(vec2(p.x, py), vec2(0.1, 0.0), vec2(0.52, 0.0), 0.075, 0.014), 0.05);
    hull = -smin(-hull, p.y + 0.03, 0.05);
    float d = smin(hull, sdTaper(p, vec2(0.02, 0.05), vec2(-0.04, 0.16), 0.055, 0.02), 0.04);
    d = smin(d, sdTaper(p, vec2(0.07, -0.02), vec2(-0.07, -0.12), 0.045, 0.012), 0.08);
    return smoothstep(aa, -aa, d);
}

void main() {
    vec2 c = vec2(0.5, 0.65);
    vec2 uv = c + (qt_TexCoord0 - c) / zoom;
    float y0 = 1.0 - uv.y;
    float x = (uv.x - 0.5) * aspect;
    float r2 = rise * 2.4;
    float y = y0 + r2 * 0.15;
    vec3 col = vec3(0.0);
    float cover = 0.0;
    if (rise < 0.5) {
    col = mix(horizon.rgb, zenith.rgb, smoothstep(0.16, 0.9, y));
    col += warm.rgb * 0.55 * exp(-length(vec2(x * 0.55, (y - 0.27) * 2.4)) * 3.0);
    col = mix(col, mix(warm.rgb, horizon.rgb, 0.3), glow * 0.55 * smoothstep(0.75, 0.15, y));
    col += warm.rgb * glow * 0.6 * exp(-length(vec2((x - pan * 0.02 - 0.25) * 0.8, (y - 0.27) * 2.2)) * 2.5);

    vec2 md = vec2(x - pan * 0.02 + lift * 0.35, y - 0.56 - lift);
    float mr = length(md);
    float disc = smoothstep(0.31 + fwidth(mr), 0.31 - fwidth(mr), mr) * (1.0 - moonless);
    float handed = rise > 0.0 ? step(0.5, moonEnd.w) : 0.0;
    float face = 0.0, mpx = fwidth(mr) / 0.31;
    if (mr < 0.32 && moonless < 0.5 && handed < 0.5) face = skyFace(vec3(md / 0.31, sqrt(max(0.0, 1.0 - dot(md, md) / 0.0961))), skyL, mpx, 0.0);
    col = mix(col, mix(col, mix(moon.rgb, warm.rgb * 1.1, glow * 0.75), face + max(smoothstep(0.0, 0.3, abs(lift)), glow) * 0.5), disc * (1.0 - handed));

    vec2 g = vec2(x * 12.0 + pan * 0.05, y * 12.0);
    vec2 cell = floor(g), f = fract(g) - 0.5;
    float r = h2(cell);
    float clusters = smoothstep(0.25, 0.75, n2(g * 0.16 + vec2(3.1, 7.7)));
    float starOn = step(mix(0.72, 0.28, clusters) - moonless * 0.14, r);
    vec2 p = f - (vec2(h2(cell + 3.1), h2(cell + 7.7)) - 0.5) * 0.7;
    float dist = length(p);
    float size = mix(0.009, 0.022, h2(cell + 1.3));
    float starDot = exp(-3.2 * (dist / size) * (dist / size)) * starOn * skyFade;
    col += starDot * 0.88 * smoothstep(0.38, 0.78, y) * (1.0 - disc) * 1.2 * (1.0 - glow * 0.6);
    vec2 s0 =vec2((h1(5.0) - 0.2) * aspect * 0.6, 0.8), dir = normalize(vec2(1.0, 0.28));
    vec2 sp = vec2(x, y) - s0;
    float along = dot(sp, dir), off = abs(dot(sp, vec2(-dir.y, dir.x)));
    col += (1.0 - smoothstep(0.0, 0.0015, off)) * smoothstep(0.0, 0.08, along) * (1.0 - smoothstep(0.06, 0.1, along))
         * smoothstep(0.38, 0.78, y) * (1.0 - disc) * 0.7 * skyFade;
    float sxw = x + pan * 0.3;
    float sc = floor(sxw / 7.0 + 0.5);
    vec2 sp0 = vec2(sxw - (sc * 7.0 + (h1(sc + 7.0) - 0.5) * 2.4), y - (0.5 + 0.25 * h1(sc + 13.0)));
    float sa = (h1(sc + 19.0) - 0.5) * 0.4, scs = cos(sa), sns = sin(sa);
    vec2 sq = vec2(scs * sp0.x + sns * sp0.y, -sns * sp0.x + scs * sp0.y);
    float skyShip = shipShape(sq, 0.09, fwidth(y)) * skyFade;
    float behind = -sq.x - 0.02;
    float tw = max(0.0018, fwidth(y) * 1.5);
    float trail = (1.0 - smoothstep(0.0, tw, abs(sq.y))) * smoothstep(-0.004, 0.0, behind) * (1.0 - smoothstep(0.0, 0.3, behind));
    col += warm.rgb * trail * 0.8 * skyFade;
    col = mix(col, mix(near.rgb, horizon.rgb, 0.18), skyShip);
    cover = skyShip;
    y = y0 + r2 * 0.35;
    float xp = x * 1.6 + pan * 0.06;
    float peaks = 0.29 + (n1(xp * 2.0) * 0.6 + n1(xp * 5.0) * 0.25 + abs(n1(xp * 11.0) - 0.5) * 0.1) * 0.08;
    float pk = under(y, peaks);
    col = mix(col, mix(far.rgb, horizon.rgb, 0.7), pk);
    cover = max(cover, pk);

    for (int i = 0; i < 3; i++) {
        float k = float(i) / 2.0;
        y = y0 + r2 * (0.45 + k * 0.2);
        float xx = x * (2.0 - k * 0.6) + pan * (0.12 + k * 0.25);
        float h = 0.28 - k * 0.03 + roll(xx, float(i) * 3.0) * (0.04 + k * 0.02);
        vec3 lc = mix(far.rgb, horizon.rgb, (1.0 - k) * 0.5) * (0.9 + 0.15 * smoothstep(h - 0.12, h, y));
        float rg = under(y, h);
        col = mix(col, lc, rg);
        cover = max(cover, rg);
        col = mix(col, mix(horizon.rgb, warm.rgb, glow * 0.6), 0.12 * exp(-abs(y - h + 0.01) * 60.0) * (1.0 - k));
        if (i == 2) {
            float tr = max(pines(x * 1.4 + pan * 0.4, y, h, 0.25, 50.0), grass(x * 1.4 + pan * 0.4, y, h, 0.12, 55.0));
            col = mix(col, mix(lc * 0.93, horizon.rgb, 0.08), tr);
            cover = max(cover, tr);
        }
    }

    y = y0 + r2 * 0.95;
    float xm = x + pan * 0.6;
    float hill = hillHeight(xm);
    float xc = (floor(xm * 30.0) + 0.5) / 30.0, pc = xc - floor(xc / 5.0 + 0.5) * 5.0;
    float grove = smoothstep(0.5, 0.75, n1(xc * 0.5 + 9.0)) * step(0.35, abs(pc));
    vec3 hillCol = near.rgb + warm.rgb * (0.07 + glow * 0.2) * exp(-abs(y - hill) * 90.0) * smoothstep(1.2, 0.0, abs(x));
    float gcell = floor(xm / 3.6 + 0.5);
    float gcx = gcell * 3.6 + (h1(gcell + 31.0) - 0.5) * 1.2;
    float gslope = (hillHeight(gcx + 0.01) - hillHeight(gcx - 0.01)) / 0.02;
    float gang = clamp(atan(gslope), -0.25, 0.25), gc = cos(gang), gs = sin(gang);
    vec2 gp = vec2(xm - gcx, y - hillHeight(gcx) - 0.004);
    float groundShip = shipShape(vec2(gc * gp.x + gs * gp.y, -gs * gp.x + gc * gp.y), 0.12, fwidth(y));
    col = mix(col, mix(near.rgb, far.rgb, 0.35), groundShip);
    float scrub = grass(xm, y, hill, (0.08 + 0.15 * grove) * step(0.2, abs(xm - gcx)), 30.0);
    float hc = max(under(y, hill), max(pines(xm, y, hill, 0.75 * grove, 0.0), scrub));
    col = mix(col, hillCol, hc);
    cover = max(cover, max(hc, groundShip));

    y = y0 + r2 * 1.5;
    float fg = 0.09 + roll(x * 0.7 + pan * 1.1, 21.0) * 0.04 - x * 0.02;
    float fc = max(under(y, fg), max(pines(x * 0.8 + pan * 1.1, y, fg, 0.12, 70.0), grass(x * 0.8 + pan * 1.1, y, fg, 0.14, 75.0)));
    col = mix(col, near.rgb * (0.68 + 0.12 * smoothstep(fg - 0.08, fg, y)), fc);
    cover = max(cover, fc);
    }

    if (rise > 0.0) {
        vec3 space = mix(vec3(0.015, 0.02, 0.05), zenith.rgb * 0.4, 0.3);
        float sp2 = smoothstep(0.22, 0.5, rise);
        col = mix(col, space + vec3(step(0.997, h2(floor(vec2(x, y0) * 260.0)))) * 0.7, sp2);
        col *= 1.0 - sp2 * clear;
        float t = clamp((rise - 0.45) / 0.55, 0.0, 1.0), p = t * t * (2.65 - 1.65 * t);
        float R = exp(mix(log(3.5), log(endR), p));
        vec2 pc = vec2(0.0, mix(mix(0.06, 0.5 + endR, p) - R, 0.5, smoothstep(0.45, 0.9, p)));
        vec2 d = vec2(x, y0) - pc;
        float rr = length(d) / R;
        float show = smoothstep(0.45, 0.52, rise) * orbit;
        vec3 L = normalize(sun.xyz);

        float aa = fwidth(rr) * 1.2;

        float mq = smoothstep(0.3, 1.0, rise);
        vec2 mc = mix(vec2(pan * 0.02, 0.56 - rise * 0.36), moonEnd.xy, mq);
        float mR = exp(mix(log(0.31), log(max(moonEnd.z, 0.001)), mq));
        vec2 md = vec2(x, y0) - mc;
        float mr = length(md) / mR, maa = fwidth(mr) * 1.2;
        vec3 mn = vec3(md / mR, sqrt(max(0.0, 1.0 - mr * mr)));
        float mpx = fwidth(mr);
        vec3 mL = normalize(mix(skyL, L, mq));
        float mfull = smoothstep(0.04, 0.55, rise), mo = 1.0;
        vec3 mcol = vec3(0.0);
        if (mr < 1.05) {
            float k = skyFace(mn, mL, mpx, mfull);
            mo = mix(k, 1.0, mfull);
            mcol = mix(moon.rgb * k, light(moonSurf(mn, mL, mpx, mfull), mn, mL, 0.0), mfull) / mo;
        }
        float ma = smoothstep(1.0 + maa, 1.0 - maa, mr) * step(0.5, moonEnd.w) * orbit * mo * (1.0 - cover);
        float front = step(1.5, moonEnd.w);

        if (rr > 1.6) {
            float a0 = mix(1.0, ma, sp2 * clear);
            fragColor = vec4((mix(col, mcol, ma) + dither()) * a0, a0) * qt_Opacity;
            return;
        }
        float ball = smoothstep(1.0 + aa, 1.0 - aa, rr) * show;
        vec3 n = vec3(d / R, sqrt(max(0.0, 1.0 - rr * rr)));
        float px = aa / 1.2;
        vec3 surf;
        if (kind > 0.5) surf = light(moonSurf(n, L, px, 1.0), n, L, 0.0);
        else {
            vec4 ps = planetSurf(n, px);
            float spec = pow(max(dot(reflect(-L, n), vec3(0.0, 0.0, 1.0)), 0.0), 24.0) * ps.a * step(rr, 1.0);
            surf = light(ps.rgb, n, L, 1.0) + mix(warm.rgb, vec3(1.0), 0.5) * spec * 0.35;
        }
        vec3 body = mix(col, mcol, ma * (1.0 - front));
        body = mix(body, surf, ball);
        body = mix(body, mcol, ma * front);
        vec2 dn = d / max(length(d), 1e-4);
        float halo = 0.5 * (1.0 - kind) * exp(-max(rr - 1.0, 0.0) * 22.0) * step(1.0, rr) * show * smoothstep(-0.4, 0.5, dot(dn, L.xy));
        body += mix(horizon.rgb, warm.rgb, 0.4) * halo;
        float a = mix(1.0, clamp(ball + halo + ma, 0.0, 1.0), sp2 * clear);
        fragColor = vec4((body + dither()) * a, a) * qt_Opacity;
        return;
    }
    float edge = mix(aspect * 0.5 + 0.7, -aspect * 0.5 - 0.7, wipe);
    fragColor = vec4(col + dither(), 1.0) * qt_Opacity * (1.0 - smoothstep(edge - 0.7, edge + 0.7, x));
}
