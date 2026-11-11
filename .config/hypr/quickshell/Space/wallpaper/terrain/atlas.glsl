// atlas
float atlasHash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float atlasNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(atlasHash(i), atlasHash(i + vec2(1.0, 0.0)), f.x),
               mix(atlasHash(i + vec2(0.0, 1.0)), atlasHash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float atlasKy(float y) {
    return y >= 0.0 ? 0.63 : 1.12;
}

float atlasDia(vec2 q, float s) {
    return (abs(q.x) / 0.54 + abs(q.y) / atlasKy(q.y) - s) * (q.y >= 0.0 ? 0.41 : 0.486);
}

vec4 atlasShape(vec2 q, float aa, vec3 L) {
    const float R = 0.19;
    vec2 p = abs(q);

    float d = atlasDia(q, 1.0), ky = atlasKy(q.y);
    float cover = 1.0 - smoothstep(-aa, aa, d);

    float r = length(q);
    float rn = min(r / R, 1.0);
    float outer = max(r - R, 0.0);
    float soft = 1.0 - smoothstep(R * 0.55, R + aa, r);

    float gm = clamp(exp(-outer * 5.0) * 1.3, 0.0, 1.0);
    vec3 n = normalize(mix(vec3(sign(q.x) / 0.54, sign(q.y) / ky, 1.2), vec3(0.0, 0.0, 2.6), gm));
    float tone = 0.15 + 0.7 * max(dot(n, L), 0.0);
    tone *= 0.7 + 0.3 * smoothstep(-1.12, 0.63, q.y);
    float tone0 = tone;

    float side = smoothstep(-0.5, -0.02, d);
    float texMask = smoothstep(R * 1.2, R * 3.0, r);

    float s = p.x / 0.54 + p.y / ky;
    float t = p.x / 0.54 - p.y / ky;
    vec2 g = vec2(s * 6.0, t * 4.0);
    vec2 cid = floor(g);
    vec2 cf = fract(g);

    float cellTone = atlasHash(cid) - 0.5;
    float lineX = 1.0 - smoothstep(0.0, 0.05, min(cf.x, 1.0 - cf.x));
    float lineY = 1.0 - smoothstep(0.0, 0.05, min(cf.y, 1.0 - cf.y));
    float broken = step(0.3, atlasHash(cid + 7.3));
    float panelLine = max(lineX, lineY) * broken;

    float grain = atlasNoise(p * 24.0) * 0.6 + atlasNoise(p * 70.0) * 0.4;
    float grime = atlasNoise(vec2(p.x * 22.0, p.y * 2.5 + 3.0));
    float wearBand = smoothstep(-0.16, -0.01, d);
    float wear = smoothstep(0.78, 0.95, atlasNoise(p * 110.0)) * wearBand;

    tone *= 1.0 + cellTone * 0.14 * texMask;
    tone *= 1.0 - 0.10 * panelLine * texMask;
    tone *= 1.0 + (grain - 0.5) * 0.35 * texMask;
    tone *= 1.0 - 0.18 * grime * grime * texMask * (0.4 + 0.6 * side);
    tone *= 1.0 - 0.2 * side * side;
    tone += wear * 0.10 * texMask;

    tone += 0.14 * smoothstep(-0.07, 0.0, d);

    float seam = 1.0 - smoothstep(0.0, aa * 1.5 + 0.01, min(p.x, p.y));
    float seamFade = smoothstep(R * 0.9, R * 2.4, r);
    tone *= 1.0 - 0.5 * seam * seamFade;

    tone = mix(tone, tone0 + 0.14 * smoothstep(-0.07, 0.0, d), gm);
    tone += cover * exp(-outer * 7.0) * 0.3;
    tone = mix(tone, 0.15, soft * 0.7);

    float dome = sqrt(max(1.0 - rn * rn, 0.0));
    float lit = 0.4 + 0.6 * max(dot(vec3(q / R * rn, dome), L), 0.0);
    float rim = pow(max(1.0 - dome, 0.0), 2.5) * 0.3;
    float heart = exp(-rn * rn * 2.5) * 0.7;
    float orb = soft * (lit + rim + heart);

    float bloom = exp(-outer * 9.0) * 0.4 + exp(-outer * 3.5) * 0.15;
    float tips = (exp(-length(vec2(q.x * 4.0, q.y - 0.63)) * 12.0) + exp(-length(vec2(q.x * 4.0, q.y + 1.12)) * 12.0)) * 0.45;
    float halo = exp(-max(d, 0.0) * 5.0) * 0.6 * (1.0 - cover);

    return vec4(tone, cover, orb + bloom + tips, halo);
}

// atlas color
vec3 atlasCol(vec4 at, float aa) {
    vec3 accent = mix(horizon.rgb, warm.rgb, 0.5);
    accent = max(mix(vec3(dot(accent, vec3(0.333))), accent, 1.5), 0.0) * 1.4;
    accent = mix(accent, vec3(1.0), clamp(at.z - 1.0, 0.0, 1.0) * 0.6);
    vec3 hull = mix(near.rgb, far.rgb, 0.45) * 1.25 * at.x
              + mix(warm.rgb, moon.rgb, 0.5) * 0.08;
    return hull + accent * at.z * atlasGlow * 0.85;
}
