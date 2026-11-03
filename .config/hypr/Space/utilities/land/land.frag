#version 440
// minimal landscape: sky, a big faint moon, sparkles, far peaks, hills in mist and pines. every edge is antialiased
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
    float starClock;
};

// no sin() hashes, they lost precision far out
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
vec3 h3(vec3 p) {
    p = fract(p * vec3(0.1031, 0.103, 0.0973) + seed * 0.011);
    p += dot(p, p.yxz + 33.33);
    return fract((p.xxy + p.yxx) * p.zyx);
}
// 3d value noise on the sphere, so continents wrap round instead of smearing like the old 2d bands
float n3(vec3 p) {
    vec3 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(h3(i).x, h3(i + vec3(1, 0, 0)).x, f.x), mix(h3(i + vec3(0, 1, 0)).x, h3(i + vec3(1, 1, 0)).x, f.x), f.y),
               mix(mix(h3(i + vec3(0, 0, 1)).x, h3(i + vec3(1, 0, 1)).x, f.x), mix(h3(i + vec3(0, 1, 1)).x, h3(i + vec3(1, 1, 1)).x, f.x), f.y), f.z);
}
// planet surface: two tone land and a little highland, soft edged so it stays clean
vec3 planetSurf(vec3 n) {
    vec3 q = n * 1.6 + seed * 0.37;
    float land = n3(q) * 0.65 + n3(q * 2.3) * 0.25 + n3(q * 5.1) * 0.1;
    vec3 s = mix(near.rgb * 1.5, far.rgb, smoothstep(0.44, 0.52, land));
    return mix(s, mix(far.rgb, moon.rgb, 0.2), smoothstep(0.62, 0.68, land) * 0.6);
}
// the sky moon's colour with soft maria
vec3 moonSurf(vec3 n) {
    return moon.rgb * mix(0.42, 0.78, n3(n * 3.2 + 11.0) * 0.7 + n3(n * 8.0 + 3.0) * 0.3);
}
// soft terminator, a night side you can still make out, and air round the rim if it has any
vec3 light(vec3 surf, vec3 n, vec3 L, float air) {
    float ndl = dot(n, L), lit = smoothstep(-0.12, 0.7, ndl);
    // airless moons get more fill so they read against black space
    surf = mix(shade.rgb + surf * mix(0.34, 0.16, air), surf * (0.6 + 0.6 * lit), lit);
    vec3 a = mix(horizon.rgb, warm.rgb, 0.4) * air + moon.rgb * 0.25 * (1.0 - air);
    return surf + a * pow(1.0 - n.z, 2.6) * (0.25 + 0.75 * smoothstep(-0.3, 0.6, ndl)) * mix(0.35, 0.8, air);
}
// smooth rolling line, a few sines with random phases
float roll(float x, float s) {
    return sin(x * 1.3 + h1(s) * 6.3) * 0.5 + sin(x * 2.9 + h1(s + 1.0) * 6.3) * 0.25 + sin(x * 6.1 + h1(s + 2.0) * 6.3) * 0.08;
}
float hillHeight(float x) {
    float peak = x - floor(x / 5.0 + 0.5) * 5.0;
    return 0.17 + roll(x * 0.8, 11.0) * 0.03 + 0.12 * (1.0 - smoothstep(0.0, 1.4, abs(peak)));
}
// how much of this pixel is under a line at height h
float under(float y, float h) {
    float aa = fwidth(y) * 0.9;
    return smoothstep(h + aa, h - aa, y);
}
// pines standing on a slope, coverage. no early return, derivatives go undefined in a branch and drew streaks everywhere
float pines(float x, float y, float ground, float dens, float s) {
    float tx = x * 46.0, ti = floor(tx), tf = fract(tx) - 0.5;
    float ax = fwidth(tx) * 1.2, ay = fwidth(y) * 0.9;
    // tall and narrow, branch tiers stepping in, a thin trunk at the bottom. squat cones looked like dwarfs
    float th = 0.05 + 0.04 * h1(ti + 4.0 + s), lift = y - ground, u = lift / th;
    float tiers = 0.3 + 0.15 * (1.0 - fract(u * 3.2 + 0.2));
    float halfw = u < 0.07 ? 0.035 : (1.0 - u) * tiers;
    float cov = smoothstep(halfw + ax, halfw - ax, abs(tf)) * smoothstep(-ay, ay, lift) * smoothstep(th + ay, th - ay, lift);
    return cov * step(h1(ti + s), dens);
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
// flat ship silhouette, nose toward +x. blended joins so there are no creases
float shipShape(vec2 q, float s, float aa) {
    vec2 p = q / s;
    aa = max(aa / s, 1e-4);
    float py = abs(p.y);
    float hull = sdTaper(vec2(p.x, py), vec2(-0.1, 0.0), vec2(0.12, 0.0), 0.075, 0.075);
    hull = smin(hull, sdTaper(vec2(p.x, py), vec2(0.1, 0.0), vec2(0.52, 0.0), 0.075, 0.014), 0.05);
    hull = -smin(-hull, p.y + 0.03, 0.05); // flat belly
    float d = smin(hull, sdTaper(p, vec2(0.02, 0.05), vec2(-0.04, 0.16), 0.055, 0.02), 0.04); // top fin
    d = smin(d, sdTaper(p, vec2(0.07, -0.02), vec2(-0.07, -0.12), 0.045, 0.012), 0.08); // swept bottom wing
    return smoothstep(aa, -aa, d);
}

void main() {
    // landing zooms in toward the peak
    vec2 c = vec2(0.5, 0.65);
    vec2 uv = c + (qt_TexCoord0 - c) / zoom;
    float y0 = 1.0 - uv.y;
    float x = (uv.x - 0.5) * aspect;
    // rise lifts the camera off the ground: near layers fall away faster than far ones
    // you cruise up first: the land sinks right out of view before space comes in, so you never see hills and the planet together
    float r2 = rise * 2.4;
    float y = y0 + r2 * 0.15;
    vec3 col = vec3(0.0);
    // up in orbit none of the landscape shows, so the star map's planets skip all of it. uniform branch, fwidth is fine
    if (rise < 0.5) {

    // sky with the warm glow sitting behind the hills
    col = mix(horizon.rgb, zenith.rgb, smoothstep(0.16, 0.9, y));
    col += warm.rgb * 0.55 * exp(-length(vec2(x * 0.55, (y - 0.27) * 2.4)) * 3.0);

    // moon, barely lighter than the sky behind it, soft texture
    vec2 md = vec2(x - pan * 0.02, y - 0.56);
    float mr = length(md);
    float tex = n1(md.x * 14.0 + md.y * 9.0 + 3.0) * n1(md.y * 17.0 - md.x * 5.0 + 9.0);
    float disc = smoothstep(0.31 + fwidth(mr), 0.31 - fwidth(mr), mr);
    // when it's about to fly up and become a real moon (star map) the one below takes over straight away
    float handed = step(0.5, moonEnd.w) * smoothstep(0.0, 0.04, rise);
    col = mix(col, mix(col, moon.rgb, 0.09 + tex * 0.07 + 0.05 * smoothstep(0.3, 0.0, length(md + vec2(0.08, -0.08)))), disc * (1.0 - handed));

    vec2 g = vec2(x * 12.0 + pan * 0.05, y * 12.0);
    vec2 cell = floor(g), f = fract(g) - 0.5;
    float r = h2(cell);
    float clusters = smoothstep(0.25, 0.75, n2(g * 0.16 + vec2(3.1, 7.7)));
    float starOn = step(mix(0.72, 0.28, clusters), r);
    vec2 p = f - (vec2(h2(cell + 3.1), h2(cell + 7.7)) - 0.5) * 0.7;
    float dist = length(p);
    float size = mix(0.009, 0.022, h2(cell + 1.3));
    float starDot = exp(-3.2 * (dist / size) * (dist / size)) * starOn;
    float rate = mix(0.6, 1.8, h2(cell + 4.9));
    float phase = h2(cell + 8.3) * 6.2831853;
    float twinkle = 0.88 + 0.12 * sin(starClock * rate + phase);
    col += starDot * twinkle * smoothstep(0.38, 0.78, y) * (1.0 - disc) * 1.2;
    vec2 s0 = vec2((h1(5.0) - 0.2) * aspect * 0.6, 0.8), dir = normalize(vec2(1.0, 0.28));
    vec2 sp = vec2(x, y) - s0;
    float along = dot(sp, dir), off = abs(dot(sp, vec2(-dir.y, dir.x)));
    col += (1.0 - smoothstep(0.0, 0.0015, off)) * smoothstep(0.0, 0.08, along) * (1.0 - smoothstep(0.06, 0.1, along))
         * smoothstep(0.38, 0.78, y) * (1.0 - disc) * 0.7;
    // sky ship with trail
    float sxw = x + pan * 0.3;
    float sc = floor(sxw / 7.0 + 0.5);
    vec2 sp0 = vec2(sxw - (sc * 7.0 + (h1(sc + 7.0) - 0.5) * 2.4), y - (0.5 + 0.25 * h1(sc + 13.0)));
    float sa = (h1(sc + 19.0) - 0.5) * 0.4, scs = cos(sa), sns = sin(sa);
    vec2 sq = vec2(scs * sp0.x + sns * sp0.y, -sns * sp0.x + scs * sp0.y);
    float skyShip = shipShape(sq, 0.09, fwidth(y));
    float behind = -sq.x - 0.02;
    float tw = max(0.0018, fwidth(y) * 1.5);
    float trail = (1.0 - smoothstep(0.0, tw, abs(sq.y))) * smoothstep(-0.004, 0.0, behind) * (1.0 - smoothstep(0.0, 0.3, behind));
    col += warm.rgb * trail * 0.8;
    col = mix(col, mix(near.rgb, horizon.rgb, 0.18), skyShip);
    // far peaks, sharp and barely there
    y = y0 + r2 * 0.35;
    float xp = x * 1.6 + pan * 0.06;
    float peaks = 0.29 + (n1(xp * 2.0) * 0.6 + n1(xp * 5.0) * 0.25 + abs(n1(xp * 11.0) - 0.5) * 0.1) * 0.08;
    col = mix(col, mix(far.rgb, horizon.rgb, 0.7), under(y, peaks));

    // rolling ranges, far to near, each with mist pooled on top
    for (int i = 0; i < 3; i++) {
        float k = float(i) / 2.0;
        y = y0 + r2 * (0.45 + k * 0.2);
        float xx = x * (2.0 - k * 0.6) + pan * (0.12 + k * 0.25);
        float h = 0.28 - k * 0.03 + roll(xx, float(i) * 3.0) * (0.04 + k * 0.02);
        vec3 lc = mix(far.rgb, horizon.rgb, (1.0 - k) * 0.5) * (0.9 + 0.15 * smoothstep(h - 0.12, h, y));
        col = mix(col, lc, under(y, h));
        col = mix(col, horizon.rgb, 0.12 * exp(-abs(y - h + 0.01) * 60.0) * (1.0 - k));
        if (i == 2) col = mix(col, lc * 0.9, pines(x * 1.4 + pan * 0.4, y, h, 0.25, 50.0));
    }

    // main hill with a peak every 5 units, rim lit where it faces the glow
    y = y0 + r2 * 0.95;
    float xm = x + pan * 0.6;
    float peak = xm - floor(xm / 5.0 + 0.5) * 5.0;
    float hill = hillHeight(xm);
    float grove = smoothstep(0.55, 0.8, 0.5 + 0.5 * sin(xm * 1.7 + h1(9.0) * 6.3)) * step(0.35, abs(peak));
    float hc = max(under(y, hill), pines(xm, y, hill, 0.75 * grove, 0.0));
    vec3 hillCol = near.rgb + warm.rgb * 0.07 * exp(-abs(y - hill) * 90.0) * smoothstep(1.2, 0.0, abs(x));
    // landed ship
    float gcell = floor(xm / 3.6 + 0.5);
    float gcx = gcell * 3.6 + (h1(gcell + 31.0) - 0.5) * 1.2;
    float gslope = (hillHeight(gcx + 0.01) - hillHeight(gcx - 0.01)) / 0.02;
    float gang = clamp(atan(gslope), -0.25, 0.25), gc = cos(gang), gs = sin(gang);
    vec2 gp = vec2(xm - gcx, y - hillHeight(gcx) - 0.004);
    float groundShip = shipShape(vec2(gc * gp.x + gs * gp.y, -gs * gp.x + gc * gp.y), 0.12, fwidth(y));
    col = mix(col, mix(near.rgb, far.rgb, 0.35), groundShip);
    col = mix(col, hillCol, hc);

    // foreground slope, darkest, a little lighter at its edge
    y = y0 + r2 * 1.5;
    float fg = 0.09 + roll(x * 0.7 + pan * 1.1, 21.0) * 0.04 - x * 0.02;
    col = mix(col, near.rgb * (0.68 + 0.12 * smoothstep(fg - 0.08, fg, y)), max(under(y, fg), pines(x * 0.8 + pan * 1.1, y, fg, 0.12, 70.0)));
    }

    // up into space: the sky goes black, the land curves away into the planet it is and the sky's moon
    // clears up and settles beside it, right where the star map has that moon
    if (rise > 0.0) {
        vec3 space = mix(vec3(0.015, 0.02, 0.05), zenith.rgb * 0.4, 0.3);
        float sp2 = smoothstep(0.22, 0.5, rise);
        col = mix(col, space + vec3(step(0.997, h2(floor(vec2(x, y0) * 260.0)))) * 0.7, sp2);
        // see-through mode drops the takeoff's dot stars, the real map is under it
        col *= 1.0 - sp2 * clear;
        // eases in but still shrinking at rise 1, the star map's camera picks up that exact speed and keeps pulling back
        // starts once space is in and is only shrinking gently by the end (slope 0.35 / 0.55 at rise 1, StarMap's pathTo matches it)
        float t = clamp((rise - 0.45) / 0.55, 0.0, 1.0), p = t * t * (2.65 - 1.65 * t);
        float R = exp(mix(log(3.5), log(endR), p));
        // rises over the horizon top first, then centres so the last of the shrink is round its middle like a real pull back
        vec2 pc = vec2(0.0, mix(mix(0.06, 0.5 + endR, p) - R, 0.5, smoothstep(0.45, 0.9, p)));
        vec2 d = vec2(x, y0) - pc;
        float rr = length(d) / R;
        float show = smoothstep(0.45, 0.52, rise) * orbit;
        vec3 L = normalize(sun.xyz);

        float aa = fwidth(rr) * 1.2;

        // the moon, moonEnd = where it ends up (x, y, radius) and w 1 behind the planet, 2 in front, 0 none
        // clears up while you cruise, then heads for its spot along with the planet. 0.36 = the sky layer's sink (0.15 * 2.4)
        float mq = smoothstep(0.3, 1.0, rise);
        vec2 mc = mix(vec2(pan * 0.02, 0.56 - rise * 0.36), moonEnd.xy, mq);
        float mR = exp(mix(log(0.31), log(max(moonEnd.z, 0.001)), mq));
        vec2 md = vec2(x, y0) - mc;
        float mr = length(md) / mR, maa = fwidth(mr) * 1.2;
        vec3 mn = vec3(md / mR, sqrt(max(0.0, 1.0 - mr * mr)));
        vec3 mcol = light(moonSurf(mn), mn, L, 0.0);
        // faint like the sky one at first, solid by the time it's up with the planet
        float ma = smoothstep(1.0 + maa, 1.0 - maa, mr) * step(0.5, moonEnd.w) * orbit
                 * smoothstep(0.0, 0.04, rise) * mix(0.14, 1.0, smoothstep(0.04, 0.55, rise));
        float front = step(1.5, moonEnd.w);

        // derivatives are all taken above this, everything past here is per pixel
        if (rr > 1.6) {
            float a0 = mix(1.0, ma, sp2 * clear);
            fragColor = vec4(mix(col, mcol, ma) * a0, a0) * qt_Opacity;
            return;
        }
        float ball = smoothstep(1.0 + aa, 1.0 - aa, rr) * show;
        vec3 n = vec3(d / R, sqrt(max(0.0, 1.0 - rr * rr)));
        vec3 surf = kind > 0.5 ? light(moonSurf(n), n, L, 0.0) : light(planetSurf(n), n, L, 1.0);
        vec3 body = mix(col, mcol, ma * (1.0 - front));
        body = mix(body, surf, ball);
        body = mix(body, mcol, ma * front);
        // thin halo just outside, lit side only, planets only
        vec2 dn = d / max(length(d), 1e-4);
        float halo = 0.5 * (1.0 - kind) * exp(-max(rr - 1.0, 0.0) * 22.0) * step(1.0, rr) * show * smoothstep(-0.4, 0.5, dot(dn, L.xy));
        body += mix(horizon.rgb, warm.rgb, 0.4) * halo;
        // clear: the space part goes see-through so the real star map shows, only the bodies stay
        float a = mix(1.0, clamp(ball + halo + ma, 0.0, 1.0), sp2 * clear);
        fragColor = vec4(body * a, a) * qt_Opacity;
        return;
    }
    fragColor = vec4(col, 1.0) * qt_Opacity;
}
