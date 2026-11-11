// space stars
vec3 skyStars(vec2 st) {
    vec3 d = normalize(vec3((viewSize.x + st.x * viewSize.z) / view.z, -(viewSize.y + st.y * viewSize.w) / view.z, 1.0));
    d = vec3(d.x, d.y * cos(view.y) + d.z * sin(view.y), -d.y * sin(view.y) + d.z * cos(view.y));
    d = vec3(d.x * cos(view.x) + d.z * sin(view.x), d.y, -d.x * sin(view.x) + d.z * cos(view.x));
    float band = exp(-abs(d.y + 0.2 * sin(d.x * 2.0 + d.z)) * 4.0);
    vec3 col = vec3(0.0);
    for (int i = 0; i < 2; i++) {
        float sc = 110.0 + float(i) * 150.0;
        vec3 q = d * sc, c = floor(q);
        float r = sh3(c);
        if (r > 0.945 - band * 0.03) {
            vec3 pt = c + 0.2 + 0.6 * vec3(sh3(c + 3.7), sh3(c + 9.1), sh3(c + 5.3));
            float dist = length(q - pt), k = sh3(c + 1.9);
            vec3 tint = k < 0.6 ? vec3(1.0) : k < 0.82 ? vec3(0.82, 0.9, 1.0) : vec3(1.0, 0.9, 0.78);
            float s = smoothstep(0.14, 0.0, dist) + exp(-dist * 7.0) * 0.12 * step(0.985, r);
            col += tint * s * (0.4 + (r - 0.94) * 8.0) / (1.0 + float(i));
        }
    }
    return col;
}
// planets
vec4 planetSurf(vec3 n, float px) {
    vec3 q = n * 1.6 + seed * 0.37;
    vec3 w = vec3(n3(q * 1.3 + 5.0), n3(q * 1.3 + 9.0), n3(q * 1.3 + 13.0)) - 0.5;
    vec3 qw = q + w * 0.7;
    float land = n3(qw) * 0.5 + n3(qw * 2.3) * 0.25 + n3(qw * 5.1) * 0.13
               + (n3(qw * 11.0) - 0.5) * 0.14 * keep(11.0, px) + (n3(qw * 23.0) - 0.5) * 0.08 * keep(23.0, px);
    float sl = 0.47 + wv(20.0) * 0.09;
    float coast = smoothstep(sl, sl + 0.02, land);
    vec3 sea = mix(near.rgb * 1.15, near.rgb * 1.7 + far.rgb * 0.12, smoothstep(sl - 0.13, sl, land));
    float ridge = 1.0 - abs(n3(qw * 6.0 + 2.0) * 2.0 - 1.0);
    float high = smoothstep(0.56, 0.72, land + ridge * ridge * 0.1);
    vec3 ground = far.rgb * mix(0.82, 1.06, n3(qw * 9.0) * keep(9.0, px) + 0.5 * (1.0 - keep(9.0, px)));
    ground = mix(ground, mix(far.rgb, moon.rgb, 0.3), high * 0.75);
    vec3 s = mix(sea, ground, coast);
    float pole = abs(n.y) + (n3(q * 5.0) - 0.5) * 0.14;
    float il = 0.84 + wv(21.0) * 0.12;
    float ice = smoothstep(il, il + 0.03, pole);
    vec3 white = mix(moon.rgb, vec3(1.0), 0.25);
    s = mix(s, white * 0.92, ice);
    vec3 cq = vec3(n.x * 2.2, n.y * 6.0, n.z * 2.2) + w * 2.2 + seed * 0.53;
    float cl = n3(cq) * 0.6 + n3(cq * 2.7) * 0.3 + (n3(cq * 6.0) - 0.5) * 0.2 * keep(14.0, px);
    float cloud = smoothstep(0.52 + wv(22.0) * 0.14, 0.72 + wv(22.0) * 0.1, cl) * 0.75;
    s = mix(s, white * 0.95, cloud);
    return vec4(s, (1.0 - coast) * (1.0 - ice) * (1.0 - cloud));
}
// craters
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
// moon
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
// lighting
vec3 light(vec3 surf, vec3 n, vec3 L, float air) {
    float ndl = dot(n, L), lit = smoothstep(-0.12, 0.7, ndl);
    surf = mix(shade.rgb + surf * mix(0.34, 0.16, air), surf * (0.6 + 0.6 * lit), lit);
    vec3 a = mix(horizon.rgb, warm.rgb, 0.4) * air + moon.rgb * 0.25 * (1.0 - air);
    return surf + a * pow(1.0 - n.z, 2.6) * (0.25 + 0.75 * smoothstep(-0.3, 0.6, ndl)) * mix(0.35, 0.8, air);
}
