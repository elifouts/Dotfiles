// hashes
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
float wv(float k) {
    return (h1(900.0 + k * 7.3) - 0.5) * 2.0 * variety;
}
// noise
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
float sh3(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.zyx + 31.32);
    return fract((p.x + p.y) * p.z);
}
// dither
vec3 dither() {
    float a = fract(52.9829189 * fract(dot(gl_FragCoord.xy, vec2(0.06711056, 0.00583715))));
    float b = fract(52.9829189 * fract(dot(gl_FragCoord.yx + 17.0, vec2(0.06711056, 0.00583715))));
    return vec3((a + b - 1.0) / 255.0);
}
float keep(float f, float px) {
    return smoothstep(0.5, 0.2, f * px);
}
float fbm2(vec2 p) {
    return n2(p) * 0.55 + n2(p * 2.3 + 3.1) * 0.3 + n2(p * 5.1 + 7.7) * 0.15;
}

// tiny point stars on a jittered grid; dens = fraction of cells that hold a star
float starLayer(vec2 p, float scale, float dens) {
    vec2 g = p * scale, id = floor(g), f = fract(g) - 0.5;
    float on  = step(h2(id), dens);
    vec2 off  = (vec2(h2(id + 7.1), h2(id + 13.7)) - 0.5) * 0.6;
    float pt  = smoothstep(0.30, 0.0, length(f - off));
    return on * pt * (0.35 + 0.65 * h2(id + 3.3));
}
